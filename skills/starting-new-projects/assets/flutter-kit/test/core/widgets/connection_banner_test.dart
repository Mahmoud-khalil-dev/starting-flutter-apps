import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/connection_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  late StreamController<ConnectionStatus> statuses;

  setUp(() => statuses = StreamController<ConnectionStatus>.broadcast());
  tearDown(() => statuses.close());

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) =>
      pumpApp(
        tester,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConnectionBanner(statuses: statuses.stream),
        ),
        reduceMotion: reduceMotion,
      );

  Future<void> emit(WidgetTester tester, ConnectionStatus status) async {
    statuses.add(status);
    await tester.pump();
    await tester.pump(Motion.standard);
  }

  testWidgets('KIT-T11: the banner is hidden online', (tester) async {
    await pump(tester);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('KIT-T11: offline, then back online for 2 s, then hidden', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, ConnectionStatus.offline);
    expect(find.text('No internet connection'), findsOneWidget);
    await emit(tester, ConnectionStatus.online);
    expect(find.text('Back online'), findsOneWidget);
    await tester.pump(Motion.bannerHold);
    await tester.pump(Motion.standard);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('KIT-T11: an unstable connection is named slow', (tester) async {
    await pump(tester);
    await emit(tester, ConnectionStatus.unstable);
    expect(find.text('The connection is slow'), findsOneWidget);
  });

  testWidgets('KIT-T11: the banner is a live region', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await emit(tester, ConnectionStatus.offline);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.liveRegion ?? false),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('KIT-T11: the banner slides from the top', (tester) async {
    await pump(tester);
    statuses.add(ConnectionStatus.offline);
    await tester.pump();
    await tester.pump(Motion.standard ~/ 3);
    final slide = tester.widget<SlideTransition>(find.byType(SlideTransition));
    expect(slide.position.value.dy, lessThan(0));
  });

  testWidgets('KIT-T11: under reduce motion the banner fades in place', (
    tester,
  ) async {
    await pump(tester, reduceMotion: true);
    statuses.add(ConnectionStatus.offline);
    await tester.pump();
    // The ticker takes its start time from the frame after the event, so
    // sample only after that frame or the fade is still at zero.
    await tester.pump(Duration.zero);
    await tester.pump(Motion.quick ~/ 3);
    final slide = tester.widget<SlideTransition>(find.byType(SlideTransition));
    expect(slide.position.value, Offset.zero);
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(ConnectionBanner),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      inExclusiveRange(0, 1),
    );
  });

  testWidgets('KIT-T11: a repeated online keeps the 2 s hold', (tester) async {
    await pump(tester);
    await emit(tester, ConnectionStatus.offline);
    await emit(tester, ConnectionStatus.online);
    await tester.pump(const Duration(milliseconds: 1000));
    statuses.add(ConnectionStatus.online);
    await tester.pump();
    await tester.pump(Duration.zero); // the frame that starts any hide
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Back online'), findsOneWidget);
    await tester.pump(Motion.bannerHold);
    await tester.pump(Motion.standard);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('KIT-T11: the banner reveal animation is built once', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, ConnectionStatus.offline);
    final first = tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(ConnectionBanner),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity;
    await emit(tester, ConnectionStatus.unstable);
    final second = tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(ConnectionBanner),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity;
    expect(identical(first, second), isTrue);
  });

  testWidgets('KIT-T11: offline is a quiet raised bar with a gold icon', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final c = AppPalette.forBrightness(brightness);
      await pumpApp(
        tester,
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: ConnectionBanner(
            statuses: Stream.empty(),
            initial: ConnectionStatus.offline,
          ),
        ),
        brightness: brightness,
      );
      final fill = tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(ConnectionBanner),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      final text = tester.widget<Text>(find.byType(Text)).style!.color!;
      final icon = tester.widget<Icon>(find.byType(Icon)).color!;
      final why = brightness.name;
      expect(fill, c.surfaceRaised, reason: why);
      expect(text, c.ink, reason: why);
      expect(icon, c.gold, reason: why);
      expect(contrastRatio(text, fill), greaterThanOrEqualTo(4.5), reason: why);
      expect(contrastRatio(icon, fill), greaterThanOrEqualTo(3), reason: why);
    }
  });
}
