import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_dialog.dart';
import 'package:kit_app/core/widgets/app_picker.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';
import 'package:kit_app/core/widgets/app_time_picker.dart';

import '../../helpers/haptics.dart';
import '../../helpers/pump_app.dart';

void main() {
  const anchor = SizedBox(key: Key('anchor'));

  testWidgets('KIT-T11: a sheet on a phone, blurred, with a handle', (
    tester,
  ) async {
    await pumpApp(tester, anchor);
    final context = tester.element(find.byKey(const Key('anchor')));
    final result = showAppSheet<String>(
      context,
      title: 'Language',
      builder: (context) => TextButton(
        onPressed: () => Navigator.pop(context, 'ar'),
        child: const Text('Arabic'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    expect(find.byKey(const Key('sheet-handle')), findsOneWidget);
    expect(
      (tester.widget<BottomSheet>(find.byType(BottomSheet)).shape!
              as RoundedRectangleBorder)
          .borderRadius,
      const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    );
    await tester.tap(find.text('Arabic'));
    await tester.pumpAndSettle();
    expect(await result, 'ar');
  });

  testWidgets('KIT-T11: a dialog from the tablet size, capped at 480', (
    tester,
  ) async {
    await pumpApp(tester, anchor, size: TestSizes.tablet);
    final context = tester.element(find.byKey(const Key('anchor')));
    unawaited(
      showAppSheet<void>(
        context,
        builder: (_) => const SizedBox(width: 2000, height: 100),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      tester.getSize(find.byType(Dialog)).width,
      lessThanOrEqualTo(AppDimensions.dialogMaxWidth),
    );
  });

  testWidgets('KIT-T11: the picker returns the tapped option with a haptic', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await pumpApp(tester, anchor);
    final result = showAppPicker<String>(
      tester.element(find.byKey(const Key('anchor'))),
      title: 'Language',
      selected: 'en',
      options: const [
        AppPickerOption(value: 'en', label: 'English'),
        AppPickerOption(value: 'ar', label: 'العربية'),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(await result, 'ar');
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  Future<Future<String?>> openSheet(
    WidgetTester tester, {
    String? title,
    bool settle = true,
  }) async {
    final result = showAppSheet<String>(
      tester.element(find.byKey(const Key('anchor'))),
      title: title,
      builder: (context) => const SizedBox(height: 40, child: Text('Body')),
    );
    if (settle) await tester.pumpAndSettle();
    return result;
  }

  final fullBlur = ImageFilter.blur(
    sigmaX: AppDimensions.backdropBlur,
    sigmaY: AppDimensions.backdropBlur,
  );

  testWidgets('KIT-T11: the settled barrier blurs with the token sigma', (
    tester,
  ) async {
    await pumpApp(tester, anchor);
    await openSheet(tester);
    final filters = tester
        .widgetList<BackdropFilter>(find.byType(BackdropFilter))
        .map((b) => b.filter);
    expect(filters, contains(fullBlur));
  });

  testWidgets('KIT-T11: under reduce motion the blur sigma is constant', (
    tester,
  ) async {
    await pumpApp(tester, anchor, reduceMotion: true);
    await openSheet(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 10));
    final filters = tester
        .widgetList<BackdropFilter>(find.byType(BackdropFilter))
        .map((b) => b.filter);
    expect(filters, contains(fullBlur));
  });

  testWidgets('KIT-T11: tapping the barrier returns null', (tester) async {
    await pumpApp(tester, anchor);
    final result = await openSheet(tester);
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(await result, isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('KIT-T11: the sheet body clears the keyboard', (tester) async {
    await pumpApp(tester, anchor);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await openSheet(tester);
    final scroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(
      scroll.padding!.resolve(TextDirection.ltr).bottom,
      AppDimensions.lg + 300,
    );
  });

  testWidgets('KIT-T11: a second open while one is showing is ignored', (
    tester,
  ) async {
    await pumpApp(tester, anchor);
    final first = showAppSheet<String>(
      tester.element(find.byKey(const Key('anchor'))),
      builder: (_) => const Text('One'),
    );
    final second = showAppSheet<String>(
      tester.element(find.byKey(const Key('anchor'))),
      builder: (_) => const Text('Two'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Two'), findsNothing);
    expect(await second, isNull);
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(await first, isNull);
    await openSheet(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('KIT-T11: a titled sheet names its route for screen readers', (
    tester,
  ) async {
    await pumpApp(tester, anchor);
    await openSheet(tester, title: 'Language');
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Language' &&
            (w.properties.scopesRoute ?? false) &&
            (w.properties.namesRoute ?? false),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('sheet-handle')),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
  });

  Future<ModalRoute<Object?>> pushBody(WidgetTester tester) async {
    unawaited(
      showAppSheet<void>(
        tester.element(find.byKey(const Key('anchor'))),
        builder: (_) => const SizedBox(height: 200, child: Text('Body')),
      ),
    );
    await tester.pump();
    return ModalRoute.of(tester.element(find.text('Body')))!;
  }

  testWidgets(
    'KIT-T11: the sheet rises over Motion.standard, never past its rest',
    (tester) async {
      await pumpApp(tester, anchor);
      final route = await pushBody(tester) as ModalBottomSheetRoute<Object?>;
      final style = route.sheetAnimationStyle!;
      expect(style.duration, Motion.standard);
      expect(style.reverseDuration, Motion.quick);
      // The route does not clamp the sheet, so an overshooting curve would
      // open a gap under it for a few frames.
      expect(style.curve, Motion.enter);
      for (var t = 0.0; t <= 1; t += 0.01) {
        expect(style.curve!.transform(t), lessThanOrEqualTo(1), reason: '$t');
      }
      expect(style.reverseCurve, Motion.exit);
      await tester.pump(Motion.standard - const Duration(milliseconds: 20));
      expect(route.animation!.status, AnimationStatus.forward);
      // One frame past the end: the controller completes once time passes it.
      await tester.pump(const Duration(milliseconds: 21));
      expect(route.animation!.status, AnimationStatus.completed);
    },
  );

  testWidgets('KIT-T11: under reduce motion the sheet fades in place', (
    tester,
  ) async {
    await pumpApp(tester, anchor, reduceMotion: true);
    final route = await pushBody(tester);
    await tester.pump(const Duration(milliseconds: 10));
    final top = tester.getTopLeft(find.byType(BottomSheet)).dy;
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(BottomSheet),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pump(Motion.quick ~/ 2);
    expect(tester.getTopLeft(find.byType(BottomSheet)).dy, top);
    await tester.pump(Motion.quick ~/ 2);
    expect(route.animation!.status, AnimationStatus.completed);
    expect(tester.getTopLeft(find.byType(BottomSheet)).dy, top);
  });

  testWidgets('KIT-T11: on the web the sheet dims without a blur', (
    tester,
  ) async {
    await pumpApp(tester, anchor, web: true);
    await openSheet(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  group('KIT-T11: a route opened from inside a sheet opens (BH-8)', () {
    Future<void> openFromPage(
      WidgetTester tester,
      WidgetBuilder inside, {
      TargetPlatform platform = TargetPlatform.android,
    }) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppSheet<void>(context, builder: inside),
            child: const Text('Open'),
          ),
        ),
        platform: platform,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('KIT-T11: a time field in a sheet opens its picker (BH-8)', (
      tester,
    ) async {
      await openFromPage(
        tester,
        (_) => AppTimePicker(label: 'Time', value: null, onChanged: (_) {}),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('KIT-T11: a confirm opened from a sheet opens (BH-8)', (
      tester,
    ) async {
      await openFromPage(
        tester,
        (context) => TextButton(
          onPressed: () => showAppDialog<void>(
            context,
            title: 'Cancel it?',
            actions: const [AppDialogAction(label: 'Keep')],
          ),
          child: const Text('Delete draft'),
        ),
      );
      await tester.tap(find.text('Delete draft'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel it?'), findsOneWidget);
    });

    testWidgets(
      'KIT-T11: a double tap on a sheet button opens one sheet (BH-8)',
      (tester) async {
        var opened = 0;
        await pumpApp(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSheet<void>(
                context,
                builder: (_) {
                  opened++;
                  return const Text('Sheet');
                },
              ),
              child: const Text('Open'),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.tap(find.text('Open'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Sheet'), findsOneWidget);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(opened, 1);
      },
    );

    testWidgets(
      'KIT-T11: a double tap inside a sheet opens one picker (BH-8)',
      (tester) async {
        var opened = 0;
        await openFromPage(
          tester,
          (_) => AppTimePicker(
            label: 'Time',
            value: null,
            pick: (_, _) {
              opened++;
              return Completer<TimeOfDay?>().future;
            },
            onChanged: (_) {},
          ),
        );
        await tester.tap(find.byType(TextField));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byType(TextField));
        await tester.pump(const Duration(seconds: 1));
        expect(opened, 1);
      },
    );
  });
}
