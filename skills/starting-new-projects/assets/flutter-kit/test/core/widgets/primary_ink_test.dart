import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/shell/app_sidebar.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_palette.dart';
import 'package:kit_app/core/widgets/app_avatar.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_loading.dart';
import 'package:kit_app/core/widgets/app_picker.dart';
import 'package:kit_app/core/widgets/app_refresh_list.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';

import '../../helpers/pump_app.dart';

final AppColors _d = AppPalette.dark;

Color? _ink(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

void main() {
  group('KIT-T11: in dark, marks in the primary hue are primaryInk', () {
    testWidgets('KIT-T11: action rows, toggles and quiet buttons', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Column(
          children: [
            AppRow.action(title: 'Sign out', onTap: () {}),
            AppRow.toggle(title: 'Alerts', value: true, onChanged: (_) {}),
            AppButton(
              label: 'Later',
              onPressed: () {},
              variant: AppButtonVariant.quiet,
            ),
          ],
        ),
        brightness: Brightness.dark,
      );
      expect(_ink(tester, 'Sign out'), _d.primaryInk);
      expect(
        tester.widget<Switch>(find.byType(Switch)).activeTrackColor,
        _d.primaryInk,
      );
      expect(_ink(tester, 'Later'), _d.primaryInk);
    });

    testWidgets('the selected segment is primaryInk with onPrimaryInk', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppSegmented<int>(
          segments: const [
            AppSegment(value: 0, label: 'Day'),
            AppSegment(value: 1, label: 'Week'),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
        brightness: Brightness.dark,
      );
      final fills = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(AppSegmented<int>),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color);
      expect(fills, contains(_d.primaryInk));
      expect(_ink(tester, 'Day'), _d.onPrimaryInk);
      expect(_ink(tester, 'Week'), _d.inkMuted);
    });

    testWidgets('spinner, pull to refresh, initials', (tester) async {
      await pumpApp(
        tester,
        Column(
          children: [
            const AppAvatar(name: 'Alex Morgan'),
            const SizedBox.square(dimension: 48, child: AppLoading()),
            Expanded(
              child: AppRefreshList(
                onRefresh: () async {},
                itemCount: 1,
                itemBuilder: (context, i) => const Text('row'),
              ),
            ),
          ],
        ),
        brightness: Brightness.dark,
        settle: false,
      );
      expect(_ink(tester, 'AM'), _d.primaryInk);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        _d.primaryInk,
      );
      expect(
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).color,
        _d.primaryInk,
      );
    });

    testWidgets('the picker check and the sidebar selection', (tester) async {
      await pumpApp(
        tester,
        Row(
          children: [
            AppSidebar(
              destinations: destinationsFor(AppRole.member),
              selected: 0,
              onTap: (_) {},
              collapsed: false,
              onToggle: () {},
            ),
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppPicker<int>(
                  context,
                  title: 'Time',
                  options: const [AppPickerOption(value: 0, label: 'Morning')],
                  selected: 0,
                ),
                child: const Text('open'),
              ),
            ),
          ],
        ),
        brightness: Brightness.dark,
        size: TestSizes.web,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home_rounded)).color,
        _d.primaryInk,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color,
        _d.primaryInk,
      );
    });
  });
}
