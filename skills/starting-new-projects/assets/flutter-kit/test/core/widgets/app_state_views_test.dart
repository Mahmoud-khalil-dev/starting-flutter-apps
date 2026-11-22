import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_loading.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';
import 'package:kit_app/core/widgets/app_state_views.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T10: AppErrorView shows the message and retries', (
    tester,
  ) async {
    var retries = 0;
    await pumpApp(
      tester,
      AppErrorView(failure: const ServerFailure(500), onRetry: () => retries++),
    );
    final l10n = l10nFor('en');
    expect(find.text(l10n.kitErrorTitle), findsOneWidget);
    expect(find.text(l10n.errorServer), findsOneWidget);
    await tester.tap(find.text(l10n.kitRetry));
    expect(retries, 1);
  });

  testWidgets('KIT-T10: NoConnection shows the offline title', (tester) async {
    await pumpApp(tester, const AppErrorView(failure: NoConnection()));
    final l10n = l10nFor('en');
    expect(find.text(l10n.kitOfflineTitle), findsOneWidget);
    expect(find.text(l10n.kitRetry), findsNothing, reason: 'no callback');
  });

  testWidgets('KIT-T10: a cancel shows the title without a body', (
    tester,
  ) async {
    await pumpApp(tester, const AppErrorView(failure: Cancelled()));
    final l10n = l10nFor('en');
    expect(find.text(l10n.kitErrorTitle), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('KIT-T10: AppEmptyView shows its default title', (tester) async {
    await pumpApp(tester, const AppEmptyView());
    expect(find.text(l10nFor('en').kitEmptyTitle), findsOneWidget);
  });

  testWidgets('KIT-T10: AppStateView shows each state and fades between', (
    tester,
  ) async {
    final status = ValueNotifier(ScreenStatus.loading);
    await pumpApp(
      tester,
      ValueListenableBuilder<ScreenStatus>(
        valueListenable: status,
        builder: (_, s, _) => AppStateView(
          status: s,
          failure: const ServerFailure(500),
          content: (_) => const Text('content'),
        ),
      ),
      settle: false,
    );
    await tester.pump(Motion.loadingDelay);
    await tester.pump();
    expect(find.byType(AppLoading), findsOneWidget);
    for (final (next, finder) in [
      (ScreenStatus.content, find.text('content')),
      (ScreenStatus.empty, find.byType(AppEmptyView)),
      (ScreenStatus.error, find.byType(AppErrorView)),
      (ScreenStatus.offline, find.byType(AppErrorView)),
    ]) {
      status.value = next;
      await tester.pump();
      await tester.pump(Motion.loadingMinShow);
      expect(find.byType(FadeTransition), findsWidgets, reason: '$next');
      await tester.pump(Motion.standard);
      await tester.pump(Motion.standard);
      expect(finder, findsOneWidget, reason: '$next');
    }
  });

  group('KIT-T10: the loading state waits calmly', () {
    Widget view(ValueNotifier<ScreenStatus> status) => ValueListenableBuilder(
      valueListenable: status,
      builder: (context, s, _) => AppStateView(
        status: s,
        loading: const Text('skeleton'),
        content: (context) => const Text('content'),
      ),
    );

    testWidgets('KIT-T10: a fast answer never shows the skeleton', (
      tester,
    ) async {
      final status = ValueNotifier(ScreenStatus.loading);
      await pumpApp(tester, view(status), settle: false);
      await tester.pump(Motion.loadingDelay ~/ 2);
      expect(find.text('skeleton'), findsNothing);
      status.value = ScreenStatus.content;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('content'), findsOneWidget);
      expect(find.text('skeleton'), findsNothing);
    });

    testWidgets('a shown skeleton stays its minimum, then content fades in', (
      tester,
    ) async {
      final status = ValueNotifier(ScreenStatus.loading);
      await pumpApp(tester, view(status), settle: false);
      await tester.pump(Motion.loadingDelay);
      await tester.pump();
      expect(find.text('skeleton'), findsOneWidget);
      status.value = ScreenStatus.content;
      await tester.pump(Motion.loadingMinShow ~/ 2);
      expect(find.text('content'), findsNothing);
      await tester.pump(Motion.loadingMinShow);
      await tester.pumpAndSettle();
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('the blank wait lays out under an unbounded height', (
      tester,
    ) async {
      // A Column child gets no height bound; the wait must not demand one.
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: Column(children: [view(ValueNotifier(ScreenStatus.loading))]),
        ),
        settle: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('skeleton'), findsNothing);
      await tester.pump(Motion.loadingDelay);
      await tester.pump();
      expect(find.text('skeleton'), findsOneWidget);
    });

    testWidgets('a status that is not loading shows at once', (tester) async {
      await pumpApp(
        tester,
        AppStateView(
          status: ScreenStatus.empty,
          content: (context) => const SizedBox(),
        ),
        settle: false,
      );
      expect(find.byType(AppEmptyView), findsOneWidget);
    });

    testWidgets('leaving the screen mid-wait leaves no timer behind', (
      tester,
    ) async {
      final status = ValueNotifier(ScreenStatus.loading);
      await pumpApp(tester, view(status), settle: false);
      await tester.pump(Motion.loadingDelay ~/ 2);
      await pumpApp(tester, const SizedBox(), settle: false);
      // flutter_test fails the test if a Timer is still pending here.
    });
  });

  group('KIT-T10: the boundaries hold', () {
    Widget view(ValueNotifier<ScreenStatus> status) => ValueListenableBuilder(
      valueListenable: status,
      builder: (context, s, _) => AppStateView(
        status: s,
        failure: const ServerFailure(500),
        loading: const Text('skeleton'),
        content: (context) => const Text('content'),
      ),
    );

    testWidgets('content at 199 ms never shows a skeleton', (tester) async {
      final status = ValueNotifier(ScreenStatus.loading);
      await pumpApp(tester, view(status), settle: false);
      await tester.pump(const Duration(milliseconds: 199));
      status.value = ScreenStatus.content;
      await tester.pump();
      expect(find.text('skeleton'), findsNothing);
      expect(find.text('content'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('skeleton'), findsNothing);
    });

    for (final (next, finder) in [
      (ScreenStatus.content, find.text('content')),
      (ScreenStatus.error, find.byType(AppErrorView)),
    ]) {
      testWidgets('$next at 250 ms waits for 680 ms', (tester) async {
        final status = ValueNotifier(ScreenStatus.loading);
        await pumpApp(tester, view(status), settle: false);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('skeleton'), findsOneWidget);
        status.value = next;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 429));
        expect(find.text('skeleton'), findsOneWidget);
        expect(finder, findsNothing);
        await tester.pump(const Duration(milliseconds: 2));
        expect(finder, findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('skeleton'), findsNothing);
      });
    }

    testWidgets('a reload keeps the old content through the delay', (
      tester,
    ) async {
      final status = ValueNotifier(ScreenStatus.content);
      await pumpApp(tester, view(status), settle: false);
      expect(find.text('content'), findsOneWidget);
      status.value = ScreenStatus.loading;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('content'), findsOneWidget);
      expect(find.text('skeleton'), findsNothing);
      // The blank wait child is never put on screen.
      expect(find.byKey(const ValueKey<ScreenStatus?>(null)), findsNothing);
      await tester.pump(const Duration(milliseconds: 101));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('skeleton'), findsOneWidget);
    });
  });
}
