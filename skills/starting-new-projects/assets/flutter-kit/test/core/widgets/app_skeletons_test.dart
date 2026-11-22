import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KIT-T11: skeletons', () {
    testWidgets(
      'KIT-T11: a row has an avatar disc and two bars of differing width',
      (tester) async {
        await pumpApp(tester, const AppSkeletonRow(), settle: false);
        final disc = tester.getSize(
          find.byKey(const ValueKey('skeleton-circle')),
        );
        expect(disc, const Size.square(AppDimensions.avatarMd));
        final bars = find.byKey(const ValueKey('skeleton-bar'));
        expect(bars, findsNWidgets(2));
        final widths = bars.evaluate().map((e) => e.size!.width).toList();
        expect(widths.first, greaterThan(widths.last));
        expect(
          tester.getSize(find.byType(AppSkeletonRow)).height,
          greaterThanOrEqualTo(AppDimensions.touchTarget),
        );
      },
    );

    testWidgets('bars start at the start edge in both languages', (
      tester,
    ) async {
      for (final language in ['en', 'ar']) {
        await pumpApp(
          tester,
          const AppSkeletonRow(leading: false),
          language: language,
          settle: false,
        );
        final row = tester.getRect(find.byType(AppSkeletonRow));
        final bar = tester.getRect(
          find.byKey(const ValueKey('skeleton-bar')).first,
        );
        if (language == 'en') {
          expect(bar.left - row.left, lessThan(row.right - bar.right));
        } else {
          expect(row.right - bar.right, lessThan(bar.left - row.left));
        }
      }
    });

    testWidgets('a card with an image keeps 16:9 above its lines', (
      tester,
    ) async {
      await pumpApp(tester, const AppSkeletonCard(image: true), settle: false);
      final image = tester.getSize(
        find.byKey(const ValueKey('skeleton-image')),
      );
      expect(image.width / image.height, closeTo(16 / 9, 0.01));
      await pumpApp(tester, const AppSkeletonCard(), settle: false);
      expect(find.byKey(const ValueKey('skeleton-image')), findsNothing);
    });

    testWidgets('a pill is not keyed as a disc', (tester) async {
      await pumpApp(tester, const AppSkeletonCard(), settle: false);
      expect(find.byKey(const ValueKey('skeleton-circle')), findsNothing);
      expect(find.byKey(const ValueKey('skeleton-bar')), findsNWidgets(2));
    });

    testWidgets('a list fills the height under one shimmer', (tester) async {
      // Center loosens pumpApp's tight screen, so the 600 applies.
      await pumpApp(
        tester,
        const Center(child: SizedBox(height: 600, child: AppSkeletonList())),
        settle: false,
      );
      expect(find.byType(AppShimmer), findsOneWidget);
      final rows = find.byType(AppSkeletonRow).evaluate().length;
      final rowHeight = tester
          .getSize(find.byType(AppSkeletonRow).first)
          .height;
      expect(rows, (600 / rowHeight).ceil());
      expect(tester.getSize(find.byType(AppSkeletonList)).height, 600);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a list with no height bound shows six rows', (tester) async {
      await pumpApp(
        tester,
        ListView(children: const [AppSkeletonList()]),
        settle: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppSkeletonRow), findsNWidgets(6));
    });

    testWidgets('a list takes the rows it is given', (tester) async {
      await pumpApp(
        tester,
        ListView(children: const [AppSkeletonList(rows: 3)]),
        settle: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppSkeletonRow), findsNWidgets(3));
    });

    testWidgets('a list says "Loading" once', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Center(child: SizedBox(height: 300, child: AppSkeletonList())),
        settle: false,
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a header is a headline-high bar and a line', (tester) async {
      await pumpApp(tester, const AppSkeletonHeader(), settle: false);
      expect(find.byKey(const ValueKey('skeleton-bar')), findsNWidgets(2));
    });

    testWidgets('a block with no width takes the width it is given', (
      tester,
    ) async {
      // A start-aligned column hands its children loose constraints, where
      // an unsized box would shrink to nothing.
      await pumpApp(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(height: 20, key: ValueKey('block')),
            AppSkeleton.line(key: ValueKey('line')),
            AppSkeleton.bar(key: ValueKey('full')),
            AppSkeleton.bar(widthFactor: 0.5, key: ValueKey('half')),
            AppSkeleton(height: 20, width: 120, key: ValueKey('fixed')),
          ],
        ),
        size: const Size(393, 852),
        settle: false,
      );
      double width(String key) =>
          tester.getSize(find.byKey(ValueKey(key))).width;
      expect(width('block'), 393);
      expect(width('line'), 393);
      expect(width('full'), 393);
      expect(width('half'), 393 / 2);
      expect(width('fixed'), 120);
    });

    testWidgets('a row lines up with the AppRow it stands for', (tester) async {
      for (final language in ['en', 'ar']) {
        await pumpApp(
          tester,
          const Column(
            children: [
              AppRow.info(
                title: 'Title',
                leading: SizedBox.square(
                  key: ValueKey('leading'),
                  dimension: AppDimensions.avatarMd,
                ),
              ),
              AppSkeletonRow(),
            ],
          ),
          language: language,
          settle: false,
        );
        final leading = tester.getRect(find.byKey(const ValueKey('leading')));
        final title = tester.getRect(find.text('Title'));
        final row = tester.getRect(find.byType(AppRow));
        final skeleton = tester.getRect(find.byType(AppSkeletonRow));
        final disc = tester.getRect(
          find.byKey(const ValueKey('skeleton-circle')),
        );
        final bar = tester.getRect(
          find.byKey(const ValueKey('skeleton-bar')).first,
        );
        expect(disc.left, leading.left, reason: language);
        expect(disc.right, leading.right, reason: language);
        expect(disc.top - skeleton.top, leading.top - row.top);
        expect(skeleton.height, row.height, reason: language);
        if (language == 'en') {
          expect(bar.left, title.left);
        } else {
          expect(bar.right, title.right);
        }
      }
    });

    testWidgets('a block with no width says why in an unbounded row', (
      tester,
    ) async {
      for (final bone in const [
        AppSkeleton(height: 20),
        AppSkeleton.line(),
        AppSkeleton.bar(),
      ]) {
        // The failed layout cascades through every ancestor; the first
        // error is the skeleton's own.
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        await pumpApp(
          tester,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [bone]),
          ),
          settle: false,
        );
        // A fresh tree for the next bone; the broken one is torn down here.
        await tester.pumpWidget(const SizedBox());
        FlutterError.onError = previous;
        expect(errors, isNotEmpty, reason: '$bone');
        expect(errors.first.exception, isA<AssertionError>());
        expect(
          errors.first.exceptionAsString(),
          contains('wrap it in Expanded or give it a width'),
        );
      }
    });
  });
}
