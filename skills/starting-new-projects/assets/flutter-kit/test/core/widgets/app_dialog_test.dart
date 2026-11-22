import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_dialog.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

const _anchor = SizedBox(key: Key('anchor'));

Future<bool?> _open(WidgetTester tester) => showAppDialog<bool>(
  tester.element(find.byKey(const Key('anchor'))),
  title: 'Delete this draft?',
  message: 'The time is released for others.',
  actions: const [
    AppDialogAction(label: 'Keep', value: false, isDefault: true),
    AppDialogAction(label: 'Delete draft', value: true, isDestructive: true),
  ],
);

Finder get _dialogScale => find.ancestor(
  of: find.byType(Dialog),
  matching: find.byType(ScaleTransition),
);

void main() {
  testWidgets('KIT-T11: the dialog is adaptive and returns the value', (
    tester,
  ) async {
    for (final (platform, type) in [
      (TargetPlatform.iOS, CupertinoAlertDialog),
      (TargetPlatform.android, Dialog),
    ]) {
      await pumpApp(tester, _anchor, platform: platform);
      final result = _open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget, reason: '$platform');
      await tester.tap(find.text('Delete draft'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    }
  });

  testWidgets('KIT-T11: one dialog at a time', (tester) async {
    await pumpApp(tester, _anchor);
    unawaited(_open(tester));
    await tester.pumpAndSettle();
    final second = _open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Delete this draft?'), findsOneWidget);
    expect(await second, isNull);
  });

  testWidgets('KIT-T11: a dialog does not open over a sheet', (tester) async {
    await pumpApp(tester, _anchor);
    final context = tester.element(find.byKey(const Key('anchor')));
    unawaited(showAppSheet<void>(context, builder: (_) => const Text('Sheet')));
    await tester.pumpAndSettle();
    expect(await _open(tester), isNull);
    expect(find.text('Delete this draft?'), findsNothing);
  });

  testWidgets('KIT-T11: the dialog blurs and springs in from 0.96', (
    tester,
  ) async {
    await pumpApp(tester, _anchor);
    unawaited(_open(tester));
    await tester.pump();
    await tester.pump(Motion.standard ~/ 10);
    expect(find.byType(BackdropFilter), findsOneWidget);
    final scale = tester.widget<ScaleTransition>(_dialogScale);
    expect(scale.scale.value, inInclusiveRange(Motion.dialogScale, 1));
    expect(scale.scale.value, lessThan(1));
    await tester.pumpAndSettle();
  });

  testWidgets('KIT-T11: under reduce motion the dialog only fades', (
    tester,
  ) async {
    await pumpApp(tester, _anchor, reduceMotion: true);
    unawaited(_open(tester));
    await tester.pump();
    await tester.pump(Motion.quick ~/ 3);
    expect(tester.widget<ScaleTransition>(_dialogScale).scale.value, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('KIT-T11: a dialog opens again after a dialog or sheet closed', (
    tester,
  ) async {
    await pumpApp(tester, _anchor);
    final context = tester.element(find.byKey(const Key('anchor')));
    final sheet = showAppSheet<void>(context, builder: (_) => const Text('S'));
    await tester.pumpAndSettle();
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    await sheet;
    final first = _open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Delete this draft?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(await first, isFalse);
    unawaited(_open(tester));
    await tester.pumpAndSettle();
    expect(find.text('Delete this draft?'), findsOneWidget);
  });

  testWidgets('KIT-T11: the barrier and the back button return null', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      await pumpApp(tester, _anchor, platform: platform);
      var closed = false;
      bool? value = true;
      void open() {
        closed = false;
        unawaited(
          _open(tester).then((v) {
            value = v;
            closed = true;
          }),
        );
      }

      open();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(closed, isTrue, reason: 'barrier $platform');
      expect(value, isNull, reason: 'barrier $platform');
      open();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, isTrue, reason: 'back $platform');
      expect(value, isNull, reason: 'back $platform');
    }
  });

  testWidgets('KIT-T11: the Material dialog names its route', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, _anchor);
    unawaited(_open(tester));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.scopesRoute ?? false) &&
            (w.properties.namesRoute ?? false) &&
            w.properties.label == 'Delete this draft?',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('KIT-T11: a destructive action carries a hint', (tester) async {
    final semantics = tester.ensureSemantics();
    final hint = l10nFor('en').kitDestructiveHint;
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      await pumpApp(tester, _anchor, platform: platform);
      unawaited(_open(tester));
      await tester.pumpAndSettle();
      final hints = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.hint == hint,
      );
      expect(hints, findsOneWidget, reason: '$platform');
      expect(
        find.descendant(of: hints, matching: find.text('Delete draft')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  });

  testWidgets('KIT-T11: under reduce motion the blur is steady and quick', (
    tester,
  ) async {
    await pumpApp(tester, _anchor, reduceMotion: true);
    unawaited(_open(tester));
    await tester.pump();
    await tester.pump(Motion.quick ~/ 10);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(
      filter.filter,
      ImageFilter.blur(
        sigmaX: AppDimensions.backdropBlur,
        sigmaY: AppDimensions.backdropBlur,
      ),
    );
    await tester.pump(Motion.quick);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('KIT-T11: on the web the dialog fades and scales, no blur', (
    tester,
  ) async {
    await pumpApp(tester, _anchor, web: true);
    unawaited(_open(tester));
    await tester.pump();
    await tester.pump(Motion.standard ~/ 10);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('KIT-T11: the web on iOS or macOS gets the Material alert', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      await pumpApp(tester, _anchor, platform: platform, web: true);
      unawaited(_open(tester));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.byType(Dialog), findsOneWidget, reason: '$platform');
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
    }
  });
}
