import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_network_image.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _Cache extends Mock implements BaseCacheManager {}

void main() {
  late _Cache cache;
  late StreamController<FileResponse> files;

  setUp(() {
    cache = _Cache();
    files = StreamController<FileResponse>();
    when(
      () => cache.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => files.stream);
  });
  // Flutter's image cache is keyed by URL and outlives a test: clear it, or
  // the next test joins this one's pending load.
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    // Not awaited: a controller nobody listened to never finishes closing.
    unawaited(files.close());
  });

  AppNetworkImage image() => AppNetworkImage(
    url: 'http://api.test/p.png',
    width: 96,
    height: 96,
    cacheManager: cache,
    semanticLabel: 'Profile photo',
  );

  testWidgets('KIT-T18: a loading image shows a shimmer', (tester) async {
    await pumpApp(tester, image(), settle: false);
    expect(find.byType(AppShimmer), findsOneWidget);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('KIT-T18: a failed image says so quietly in $language', (
      tester,
    ) async {
      await pumpApp(tester, image(), language: language, settle: false);
      files.addError(Exception('404'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(AppShimmer), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(language == 'ar' ? 'الصورة غير متاحة' : 'Image unavailable'),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('KIT-T18: reduce motion shortens the fade', (tester) async {
    await pumpApp(tester, image(), reduceMotion: true, settle: false);
    final widget = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(widget.fadeInDuration <= Motion.quick, isTrue);
  });

  testWidgets('KIT-T18: the fade keeps its length with motion on', (
    tester,
  ) async {
    await pumpApp(tester, image(), settle: false);
    final widget = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(widget.fadeInDuration, Motion.standard);
  });

  testWidgets('KIT-T18: no address is the quiet state with no request', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AppNetworkImage(url: '', width: 96, height: 96, cacheManager: cache),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.bySemanticsLabel('Image unavailable'), findsOneWidget);
    verifyZeroInteractions(cache);
  });

  testWidgets('KIT-T18: a failed image can be tried again', (tester) async {
    when(() => cache.removeFile(any())).thenAnswer((_) async {});
    await pumpApp(tester, image(), settle: false);
    files.addError(Exception('404'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    verify(
      () => cache.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).called(1);
    // The second load is a stream of its own, still waiting.
    when(
      () => cache.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => StreamController<FileResponse>().stream);
    await tester.tap(find.byIcon(Icons.image_not_supported_outlined));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    verify(() => cache.removeFile(any())).called(1);
    expect(find.byType(AppShimmer), findsOneWidget);
    verify(
      () => cache.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).called(1); // the load after the tap, not the first
  });

  testWidgets('KIT-T18: an image is decoded at its slot size', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(devicePixelRatio: 3),
          child: image(),
        ),
      ),
      settle: false,
    );
    final widget = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(widget.memCacheWidth, 288);
    expect(widget.memCacheHeight, 288);
  });

  for (final (label, width, height) in [
    ('zero', 0.0, 0.0),
    ('infinite', double.infinity, double.infinity),
  ]) {
    testWidgets('KIT-T18: a $label slot size skips the sizing', (tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 96,
          height: 96,
          child: AppNetworkImage(
            url: 'http://api.test/p.png',
            width: width,
            height: height,
            cacheManager: cache,
          ),
        ),
        settle: false,
      );
      final widget = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(widget.memCacheWidth, isNull);
      expect(widget.memCacheHeight, isNull);
    });
  }
}
