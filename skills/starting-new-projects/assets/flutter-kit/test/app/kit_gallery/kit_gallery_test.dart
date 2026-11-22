import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_screen.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_sections.dart';
import 'package:kit_app/core/l10n/digits.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_logo_loader.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';
import 'package:kit_app/core/widgets/permission_prompt.dart';
import 'package:kit_app/l10n/app_localizations.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

final _clock = FixedClock(DateTime(2026, 11, 20, 9));

Future<void> _pumpSection(
  WidgetTester tester,
  KitSection section, {
  String language = 'en',
  Brightness brightness = Brightness.light,
  Size size = TestSizes.phone,
  bool reduceMotion = false,
  bool settle = true,
}) => pumpApp(
  tester,
  SingleChildScrollView(child: section.build(clock: _clock)),
  language: language,
  brightness: brightness,
  size: size,
  reduceMotion: reduceMotion,
  settle: settle,
);

/// The Scaffold keeps an empty floating-action-button slot at scale 0. It
/// is the framework's, shows nothing and is not a kit element.
bool _isScaffoldFabSlot(WidgetTester tester, ScaleTransition transition) {
  var inSlot = false;
  tester.element(find.byWidget(transition)).visitAncestorElements((a) {
    inSlot =
        a.widget.runtimeType.toString() == '_FloatingActionButtonTransition';
    return !inSlot;
  });
  return inSlot;
}

void main() {
  testWidgets('KIT-T11: every section renders in every variant', (
    tester,
  ) async {
    for (final section in KitSection.values) {
      for (final language in ['en', 'ar']) {
        for (final brightness in Brightness.values) {
          for (final size in [
            TestSizes.phone,
            TestSizes.tablet,
            TestSizes.web,
          ]) {
            await _pumpSection(
              tester,
              section,
              language: language,
              brightness: brightness,
              size: size,
              settle: false,
            );
            await tester.pump(Motion.slow);
            expect(
              tester.takeException(),
              isNull,
              reason: '$section $language $brightness $size',
            );
          }
        }
      }
    }
  });

  testWidgets('KIT-T11: under reduce motion nothing moves or scales', (
    tester,
  ) async {
    for (final section in KitSection.values) {
      await _pumpSection(tester, section, reduceMotion: true, settle: false);
      await tester.pump(Motion.instant);
      for (final s in tester.widgetList<SlideTransition>(
        find.byType(SlideTransition),
      )) {
        expect(s.position.value, Offset.zero, reason: '$section');
      }
      for (final s in tester.widgetList<ScaleTransition>(
        find.byType(ScaleTransition),
      )) {
        if (_isScaffoldFabSlot(tester, s)) continue;
        expect(s.scale.value, 1, reason: '$section');
      }
      for (final s in tester.widgetList<AnimatedScale>(
        find.byType(AnimatedScale),
      )) {
        expect(s.scale, 1, reason: '$section');
      }
    }
  });

  testWidgets('KIT-T11: in Arabic the gallery shows no Western digit', (
    tester,
  ) async {
    for (final section in KitSection.values) {
      await _pumpSection(tester, section, language: 'ar', settle: false);
      await tester.pump(Motion.slow);
      for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
        final plain = text.text.toPlainText();
        expect(hasWesternDigit(plain), isFalse, reason: '$section: $plain');
      }
    }
  });

  test('KIT-T11: the gallery holds no data layer', () {
    final banned = RegExp(
      r'Repository|DataSource|jsonDecode|fromJson|sl<|sl\(|\bDio\b',
    );
    for (final file in Directory('lib/app/kit_gallery').listSync()) {
      final source = File(file.path).readAsStringSync();
      expect(banned.hasMatch(source), isFalse, reason: file.path);
    }
  });

  testWidgets('KIT-T11: the language toggle switches to Arabic', (
    tester,
  ) async {
    await pumpApp(tester, KitGalleryScreen(clock: _clock), settle: false);
    await tester.pump(Motion.slow);
    await tester.tap(find.text('العربية'));
    await tester.pump(Motion.slow);
    expect(
      Directionality.of(
        tester.element(find.byType(KitSection.foundations.type)),
      ),
      TextDirection.rtl,
    );
  });

  testWidgets(
    'KIT-T11: the gallery in Arabic gets Arabic-Indic picker digits by itself',
    (tester) async {
      // The live App has no digit delegates, so the gallery brings its own.
      tester.view
        ..physicalSize = TestSizes.phone
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: KitGalleryScreen(clock: _clock),
        ),
      );
      await tester.pump(Motion.slow);
      await tester.tap(find.text('العربية'));
      await tester.pump(Motion.slow);
      final inside = tester.element(find.byType(KitSection.foundations.type));
      expect(MaterialLocalizations.of(inside).formatDecimal(5), '٥');
      expect(
        CupertinoLocalizations.of(inside).datePickerDayOfMonth(5),
        contains('٥'),
      );
    },
  );

  testWidgets('KIT-T11: the date launcher opens on the gallery clock day', (
    tester,
  ) async {
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: KitSection.feedback.build(
          clock: FixedClock(DateTime(2031, 3, 10, 9)),
        ),
      ),
      settle: false,
    );
    await tester.pump(Motion.slow);
    await tester.tap(find.text('Date'));
    await tester.pump();
    await tester.pump(Motion.slow);
    expect(find.textContaining('2031'), findsWidgets);
  });

  testWidgets('KIT-T11: every swatch is labelled in ink that reads on it', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await _pumpSection(
        tester,
        KitSection.foundations,
        brightness: brightness,
      );
      final labels = find.descendant(
        of: find.byType(Wrap).first,
        matching: find.byType(Text),
      );
      expect(labels, findsWidgets);
      for (final element in labels.evaluate()) {
        final text = element.widget as Text;
        final swatch = element.findAncestorWidgetOfExactType<Container>()!;
        final fill = (swatch.decoration! as BoxDecoration).color!;
        expect(
          contrastRatio(text.style!.color!, fill),
          greaterThanOrEqualTo(4.5),
          reason: '${text.data} in ${brightness.name}',
        );
      }
    }
  });

  testWidgets('KIT-T11: the type samples all start at the start edge', (
    tester,
  ) async {
    for (final (language, marker) in [
      ('en', 'a calm summary'),
      ('ar', 'ملخّص هادئ'),
    ]) {
      await _pumpSection(tester, KitSection.foundations, language: language);
      final edges = {
        for (final element in find.textContaining(marker).evaluate())
          language == 'ar'
              ? tester.getTopRight(find.byWidget(element.widget)).dx
              : tester.getTopLeft(find.byWidget(element.widget)).dx,
      };
      expect(edges, hasLength(1), reason: language);
    }
  });

  testWidgets('KIT-T11: in Arabic the state titles are Arabic', (tester) async {
    await _pumpSection(
      tester,
      KitSection.states,
      language: 'ar',
      settle: false,
    );
    final titles = [
      for (final g in tester.widgetList<AppGroup>(find.byType(AppGroup)))
        ?g.title,
    ];
    expect(titles, isNotEmpty);
    for (final title in titles) {
      expect(title, isNot(matches(RegExp('[A-Za-z]'))), reason: title);
    }
  });

  testWidgets('KIT-T11: the logo loader sits inline and replays its wait', (
    tester,
  ) async {
    const long = 'Still preparing this. Thank you for waiting.';
    await _pumpSection(tester, KitSection.loading, settle: false);
    final loader = find.byType(AppLogoLoader);
    expect(loader, findsOneWidget);
    expect(tester.widget<AppLogoLoader>(loader).fullScreen, isFalse);
    await tester.pump(Motion.longWait);
    await tester.pump(Motion.gentle);
    expect(find.text(long), findsOneWidget);

    final replay = find.text('Start the wait again');
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await tester.pump();
    expect(find.text(long), findsNothing, reason: 'a fresh loader');
    await tester.pump(Motion.longWait - Motion.tick);
    expect(find.text(long), findsNothing);
    await tester.pump(Motion.tick);
    await tester.pump(Motion.gentle);
    expect(find.text(long), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('KIT-T11: the state skeletons span the frame at 393 px', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      KitSection.states,
      size: const Size(393, 852),
      settle: false,
    );
    await tester.pump(Motion.slow);
    final list = find.descendant(
      of: find.byType(KitSection.states.type),
      matching: find.byType(AppSkeletonList),
    );
    expect(list, findsOneWidget);
    final rows = find.descendant(
      of: list,
      matching: find.byType(AppSkeletonRow),
    );
    expect(rows, findsWidgets);
    final listWidth = tester.getSize(list).width;
    expect(listWidth, greaterThan(393 / 2));
    final bars = find.descendant(
      of: rows.first,
      matching: find.byKey(const ValueKey('skeleton-bar')),
    );
    expect(bars, findsNWidgets(2));
    for (final bar in bars.evaluate()) {
      expect(bar.size!.width, greaterThan(listWidth / 4));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T11: a drag on a state frame still scrolls the gallery', (
    tester,
  ) async {
    await pumpApp(
      tester,
      KitGalleryScreen(clock: _clock),
      size: const Size(393, 852),
      settle: false,
    );
    await tester.pump(Motion.slow);
    final gallery = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(gallery).position;

    // Drags from the middle of the screen, as a thumb does, until [target]
    // is on screen; fails if the gallery stops moving first.
    Future<void> dragTo(Finder target) async {
      while (target.hitTestable().evaluate().isEmpty) {
        final before = position.pixels;
        await tester.drag(gallery, const Offset(0, -300));
        await tester.pump(Motion.slow);
        expect(tester.takeException(), isNull);
        expect(
          position.pixels,
          greaterThan(before),
          reason: 'the gallery stopped before $target',
        );
      }
    }

    final offline = find.descendant(
      of: find.byType(KitSection.states.type),
      matching: find.text('You are offline'),
    );
    await dragTo(offline);
    // The frame's error copy overflows it, so its own scroll view could
    // take the drag; the gallery must move instead.
    final before = position.pixels;
    await tester.drag(offline, const Offset(0, -300));
    await tester.pump(Motion.slow);
    expect(position.pixels, greaterThan(before));

    await dragTo(find.text('Start the wait again'));
    await dragTo(find.text('Shell'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('KIT-T17: the permissions section shows every state', (
    tester,
  ) async {
    for (final language in ['en', 'ar']) {
      await _pumpSection(tester, KitSection.permissions, language: language);
      expect(find.byType(PermissionPrompt), findsNWidgets(7));
      expect(tester.takeException(), isNull, reason: language);
    }
  });
}
