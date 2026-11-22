import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/widgets/app_paged_list.dart';
import 'package:kit_app/core/widgets/app_refresh_list.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

Widget _row(BuildContext _, int i) =>
    SizedBox(height: 80, child: Text('row $i'));

void main() {
  testWidgets('KIT-T11: AppRefreshList is adaptive and refreshes', (
    tester,
  ) async {
    for (final (platform, type) in [
      (TargetPlatform.android, RefreshIndicator),
      (TargetPlatform.iOS, CupertinoSliverRefreshControl),
    ]) {
      var refreshes = 0;
      await pumpApp(
        tester,
        AppRefreshList(
          onRefresh: () async => refreshes++,
          itemCount: 20,
          itemBuilder: _row,
        ),
        platform: platform,
      );
      // The Cupertino control has no extent at rest, so the finder counts
      // it as offstage.
      expect(
        find.byType(type, skipOffstage: false),
        findsOneWidget,
        reason: '$platform',
      );
      await tester.fling(find.text('row 0'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(refreshes, 1, reason: '$platform');
    }
  });

  testWidgets('KIT-T11: AppPagedList loads more once near the end', (
    tester,
  ) async {
    var loads = 0;
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 20,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () => loads++,
        hasMore: true,
      ),
    );
    expect(loads, 0);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -10));
    await tester.pump();
    expect(loads, 1);
  });

  testWidgets('KIT-T11: loading more shows two skeleton rows', (tester) async {
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 2,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () {},
        loadingMore: true,
      ),
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppSkeletonRow), findsNWidgets(2));
  });

  testWidgets('KIT-T11: AppPagedList shows a spinner, then the footer error', (
    tester,
  ) async {
    var retries = 0;
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 2,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () {},
        loadingMore: true,
      ),
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppSkeletonRow), findsNWidgets(2));
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 2,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () {},
        loadMoreError: 'This could not be loaded',
        onRetryMore: () => retries++,
      ),
    );
    expect(find.text('This could not be loaded'), findsOneWidget);
    await tester.tap(find.text(l10nFor('en').kitRetry));
    expect(retries, 1);
  });

  testWidgets('KIT-T11: AppPagedList asks for nothing without more', (
    tester,
  ) async {
    var loads = 0;
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 20,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () => loads++,
      ),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump();
    expect(loads, 0);
  });

  testWidgets('KIT-T11: AppPagedList pages again after a refresh', (
    tester,
  ) async {
    var loads = 0;
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 20,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () => loads++,
        hasMore: true,
      ),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -10));
    await tester.pump();
    expect(loads, 1);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pump();
    await tester.fling(find.text('row 0'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -10));
    await tester.pump();
    expect(loads, 2, reason: 'same item count after a refresh');
  });

  testWidgets('KIT-T11: AppPagedList loads when the first page is short', (
    tester,
  ) async {
    var loads = 0;
    await pumpApp(
      tester,
      AppPagedList(
        itemCount: 2,
        itemBuilder: _row,
        onRefresh: () async {},
        onLoadMore: () => loads++,
        hasMore: true,
      ),
    );
    expect(loads, 1);
  });
}
