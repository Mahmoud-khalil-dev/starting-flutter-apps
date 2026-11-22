import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/api_messages_listener.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';
import 'package:kit_app/core/widgets/app_snackbar.dart';
import 'package:kit_app/core/widgets/success_check.dart';

import '../../helpers/haptics.dart';
import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

const _anchor = Scaffold(body: SizedBox(key: Key('anchor')));

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byKey(const Key('anchor')));

void main() {
  testWidgets('KIT-T11: a second snackbar replaces the first', (tester) async {
    await pumpApp(tester, _anchor);
    final context = _context(tester);
    AppSnackbar.show(context, 'Saved');
    await tester.pumpAndSettle();
    AppSnackbar.show(context, 'Copied', tone: SnackTone.danger);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Copied'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppPalette.light.danger,
    );
  });

  testWidgets('KIT-T11: a failed write shows; a cancel never does', (
    tester,
  ) async {
    final messages = StreamController<Failure>();
    addTearDown(messages.close);
    await pumpApp(
      tester,
      ApiMessagesListener(
        messages: messages.stream,
        child: const Scaffold(body: SizedBox()),
      ),
    );
    messages.add(const Cancelled());
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    messages.add(const ServerFailure(500));
    await tester.pumpAndSettle();
    expect(find.text(l10nFor('en').errorServer), findsOneWidget);
  });

  testWidgets(
    'KIT-T11: the success tone draws a check, shimmers and gives a haptic',
    (tester) async {
      final haptics = recordHaptics(tester);
      await pumpApp(tester, _anchor);
      AppSnackbar.show(_context(tester), 'Saved', tone: SnackTone.success);
      await tester.pump();
      await tester.pump(Motion.quick);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      expect(find.byType(SuccessCheck), findsOneWidget);
      expect(find.byType(AppShimmer), findsNothing, reason: 'still drawing');
      final state = tester.state<SuccessCheckState>(find.byType(SuccessCheck));
      expect(state.progress, inExclusiveRange(0, 1));
      await tester.pump(Motion.slow);
      expect(state.progress, 1);
      expect(find.byType(AppShimmer), findsOneWidget);
      await tester.pump(Motion.shimmerPeriod);
      expect(find.byType(AppShimmer), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('KIT-T11: under reduce motion the check is drawn, still', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await pumpApp(tester, _anchor, reduceMotion: true);
    AppSnackbar.show(_context(tester), 'Saved', tone: SnackTone.success);
    await tester.pump();
    final state = tester.state<SuccessCheckState>(find.byType(SuccessCheck));
    expect(state.progress, 1);
    expect(find.byType(AppShimmer), findsNothing);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
    await tester.pumpAndSettle();
  });

  testWidgets('KIT-T11: neutral and danger show no check and no haptic', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await pumpApp(tester, _anchor);
    AppSnackbar.show(_context(tester), 'Copied');
    await tester.pumpAndSettle();
    expect(find.byType(SuccessCheck), findsNothing);
    expect(haptics, isEmpty);
  });

  testWidgets('KIT-T11: the snackbar is a live region', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, _anchor);
    AppSnackbar.show(_context(tester), 'Saved');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.liveRegion ?? false),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('KIT-T11: a burst leaves one message; identical repeats once', (
    tester,
  ) async {
    await pumpApp(tester, _anchor);
    final context = _context(tester);
    AppSnackbar.show(context, 'One');
    AppSnackbar.show(context, 'Two');
    AppSnackbar.show(context, 'Three');
    await tester.pump();
    await tester.pump(Motion.quick);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    await tester.pumpAndSettle(Motion.snackbarHold);
  });

  testWidgets('KIT-T11: an identical message still showing is not repeated', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await pumpApp(tester, _anchor);
    final context = _context(tester);
    AppSnackbar.show(context, 'Saved', tone: SnackTone.success);
    await tester.pump(Motion.quick);
    AppSnackbar.show(context, 'Saved', tone: SnackTone.success);
    await tester.pump(Motion.quick);
    expect(haptics, hasLength(1));
    await tester.pump(Motion.standard);
    await tester.pump(Motion.snackbarHold);
    await tester.pumpAndSettle();
    AppSnackbar.show(context, 'Saved', tone: SnackTone.success);
    await tester.pump(Motion.quick);
    expect(haptics, hasLength(2));
    await tester.pumpAndSettle(Motion.snackbarHold);
  });

  testWidgets('KIT-T11: the snackbar holds for Motion.snackbarHold', (
    tester,
  ) async {
    await pumpApp(tester, _anchor);
    AppSnackbar.show(_context(tester), 'Saved');
    await tester.pump();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      Motion.snackbarHold,
    );
    await tester.pumpAndSettle(Motion.snackbarHold);
  });

  group('KIT-T11: ApiMessagesListener', () {
    testWidgets('dispose cancels and a new stream resubscribes', (
      tester,
    ) async {
      var cancelled = 0;
      final first = StreamController<Failure>(onCancel: () => cancelled++);
      final second = StreamController<Failure>();
      addTearDown(second.close);
      final current = ValueNotifier<Stream<Failure>>(first.stream);
      addTearDown(current.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<Stream<Failure>>(
          valueListenable: current,
          builder: (context, stream, _) => ApiMessagesListener(
            messages: stream,
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      );
      current.value = second.stream;
      await tester.pump();
      expect(cancelled, 1);
      second.add(const ServerFailure(500));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(second.hasListener, isFalse);
    });

    testWidgets('without a messenger or localizations nothing throws', (
      tester,
    ) async {
      final messages = StreamController<Failure>();
      addTearDown(messages.close);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ApiMessagesListener(
            messages: messages.stream,
            child: const SizedBox(),
          ),
        ),
      );
      messages.add(const ServerFailure(500));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a stream error is swallowed', (tester) async {
      final messages = StreamController<Failure>();
      addTearDown(messages.close);
      await pumpApp(
        tester,
        ApiMessagesListener(
          messages: messages.stream,
          child: const Scaffold(body: SizedBox()),
        ),
      );
      messages.addError(Exception('boom'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
