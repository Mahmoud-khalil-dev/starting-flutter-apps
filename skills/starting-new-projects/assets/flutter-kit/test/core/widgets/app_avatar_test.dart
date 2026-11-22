import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/widgets/app_avatar.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T11: the avatar holds its square and shows initials', (
    tester,
  ) async {
    await pumpApp(tester, const Center(child: AppAvatar(name: 'alex morgan')));
    expect(
      tester.getSize(find.byType(AppAvatar)),
      const Size.square(AppDimensions.avatarMd),
    );
    expect(find.text('AM'), findsOneWidget);
  });

  testWidgets('KIT-T11: Arabic names give Arabic initials', (tester) async {
    await pumpApp(
      tester,
      const AppAvatar(name: 'أليكس مورغان'),
      language: 'ar',
    );
    expect(find.text('أم'), findsOneWidget);
  });

  testWidgets('KIT-T11: a failed image falls back to initials', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: AppAvatar(
          image: MemoryImage(Uint8List.fromList([0, 1, 2])),
          name: 'Alex',
          size: AppDimensions.avatarLg,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('A'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppAvatar)),
      const Size.square(AppDimensions.avatarLg),
    );
  });

  testWidgets('KIT-T11: the avatar keeps its square while the image loads', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Center(
        child: AppAvatar(
          image: MemoryImage(Uint8List.fromList([0, 1, 2])),
          name: 'Alex',
          size: AppDimensions.avatarLg,
        ),
      ),
      settle: false,
    );
    expect(
      tester.getSize(find.byType(AppAvatar)),
      const Size.square(AppDimensions.avatarLg),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T11: a hero tag wraps the avatar in a Hero', (tester) async {
    await pumpApp(tester, const AppAvatar(name: 'Alex', heroTag: 'hero-7'));
    expect(tester.widget<Hero>(find.byType(Hero)).tag, 'hero-7');
  });

  testWidgets('KIT-T11: the avatar is announced once, by name', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, const AppAvatar(name: 'alex morgan'));
    expect(find.bySemanticsLabel('alex morgan'), findsOneWidget);
    expect(find.bySemanticsLabel('AM'), findsNothing);
    semantics.dispose();
  });

  testWidgets('KIT-T11: a tight parent does not squash the avatar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: SizedBox(width: 100, height: 40, child: AppAvatar(name: 'Alex')),
      ),
    );
    expect(tester.getSize(find.byType(AppAvatar)), const Size(100, 40));
    // getSize ignores the FittedBox scale; the painted corners do not.
    final disc = find.byType(ClipOval);
    final painted = tester.getBottomRight(disc) - tester.getTopLeft(disc);
    expect(painted, const Offset(40, 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T11: a large tight parent does not grow the avatar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: AppAvatar(name: 'Alex'),
        ),
      ),
    );
    final disc = find.byType(ClipOval);
    final painted = tester.getBottomRight(disc) - tester.getTopLeft(disc);
    expect(painted, const Offset(48, 48));
  });

  testWidgets('KIT-T11: the avatar survives intrinsic sizing', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: IntrinsicHeight(
          child: Row(children: [AppAvatar(name: 'Alex')]),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ClipOval)),
      const Size.square(AppDimensions.avatarMd),
    );
  });

  testWidgets('KIT-T11: the image decodes at the displayed size', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AppAvatar(
        image: MemoryImage(Uint8List.fromList([0, 1, 2])),
        name: 'Alex',
      ),
      settle: false,
    );
    final provider = tester.widget<Image>(find.byType(Image)).image;
    expect(provider, isA<ResizeImage>());
    // Cover keeps the short side >= the target: a fit bound of twice the
    // target holds that for portraits up to 2:1.
    final resize = provider as ResizeImage;
    expect(resize.policy, ResizeImagePolicy.fit);
    expect(resize.width, AppDimensions.avatarMd.round() * 2);
    expect(resize.height, AppDimensions.avatarMd.round() * 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T11: initials reach 4.5:1 on the disc in both themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpApp(
        tester,
        const Center(child: AppAvatar(name: 'alex morgan')),
        brightness: brightness,
      );
      final ink = tester.widget<Text>(find.text('AM')).style!.color!;
      final disc = tester
          .widget<ColoredBox>(
            find
                .ancestor(
                  of: find.text('AM'),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;
      expect(
        contrastRatio(ink, disc),
        greaterThanOrEqualTo(4.5),
        reason: brightness.name,
      );
    }
  });
}
