import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/l10n/digits.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/permission_prompt.dart';

import '../../helpers/l10n.dart';
import '../../helpers/pump_app.dart';

void main() {
  for (final language in ['en', 'ar']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'KIT-T17: each state offers the right step in $language ${brightness.name}',
        (tester) async {
          final l10n = l10nFor(language);
          var requested = 0;
          var opened = 0;
          Future<void> show(PermissionState state) => pumpApp(
            tester,
            PermissionPrompt(
              permission: AppPermission.camera,
              state: state,
              onRequest: () => requested++,
              onOpenSettings: () => opened++,
            ),
            language: language,
            brightness: brightness,
          );

          await show(PermissionState.notAsked);
          expect(find.text(l10n.permissionCameraTitle), findsOneWidget);
          expect(find.text(l10n.permissionCameraBody), findsOneWidget);
          await tester.tap(find.text(l10n.permissionAllow));
          expect(requested, 1);

          await show(PermissionState.denied);
          expect(find.text(l10n.permissionDeniedBody), findsOneWidget);
          await tester.tap(find.text(l10n.permissionAllow));
          expect(requested, 2);

          for (final state in [
            PermissionState.permanentlyDenied,
            PermissionState.revoked,
            PermissionState.limited,
          ]) {
            await show(state);
            await tester.tap(find.text(l10n.permissionOpenSettings));
          }
          expect(opened, 3);
          await show(PermissionState.revoked);
          expect(find.text(l10n.permissionRevokedBody), findsOneWidget);
          await show(PermissionState.limited);
          expect(find.text(l10n.permissionLimitedBody), findsOneWidget);

          await show(PermissionState.granted);
          expect(find.text(l10n.permissionGranted), findsOneWidget);
          expect(find.text(l10n.permissionAllow), findsNothing);
          await show(PermissionState.unavailable);
          expect(find.text(l10n.permissionUnavailable), findsOneWidget);
          expect(find.text(l10n.permissionOpenSettings), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('KIT-T17: every permission explains itself in both languages', (
    tester,
  ) async {
    for (final language in ['en', 'ar']) {
      final l10n = l10nFor(language);
      final expected = {
        AppPermission.notifications: l10n.permissionNotificationsTitle,
        AppPermission.camera: l10n.permissionCameraTitle,
        AppPermission.photos: l10n.permissionPhotosTitle,
      };
      for (final MapEntry(key: permission, value: title) in expected.entries) {
        await pumpApp(
          tester,
          PermissionPrompt(
            permission: permission,
            state: PermissionState.notAsked,
            onRequest: () {},
            onOpenSettings: () {},
          ),
          language: language,
        );
        expect(
          find.text(title),
          findsOneWidget,
          reason: '$language $permission',
        );
      }
    }
  });

  testWidgets('KIT-T17: the copy holds no Western digit in Arabic', (
    tester,
  ) async {
    for (final state in PermissionState.values) {
      await pumpApp(
        tester,
        PermissionPrompt(
          permission: AppPermission.photos,
          state: state,
          onRequest: () {},
          onOpenSettings: () {},
        ),
        language: 'ar',
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final text in texts) {
        expect(hasWesternDigit(text.data ?? ''), isFalse, reason: '$state');
      }
    }
  });

  testWidgets(
    'KIT-T17: under reduce motion a change of state is a short fade',
    (tester) async {
      Future<void> show(PermissionState state) => pumpApp(
        tester,
        PermissionPrompt(
          permission: AppPermission.camera,
          state: state,
          onRequest: () {},
          onOpenSettings: () {},
        ),
        reduceMotion: true,
        settle: false,
      );
      await show(PermissionState.notAsked);
      await show(PermissionState.granted);
      // The fade runs, at most Motion.quick, then the old copy is gone.
      await tester.pump();
      await tester.pump(Motion.quick);
      await tester.pump(Motion.instant);
      expect(find.text(l10nFor('en').permissionGranted), findsOneWidget);
      expect(find.text(l10nFor('en').permissionCameraBody), findsNothing);
    },
  );

  testWidgets('KIT-T17: a large text size never overflows', (tester) async {
    for (final state in PermissionState.values) {
      await pumpApp(
        tester,
        PermissionPrompt(
          permission: AppPermission.notifications,
          state: state,
          onRequest: () {},
          onOpenSettings: () {},
        ),
        language: 'ar',
        textScale: 2,
      );
      expect(tester.takeException(), isNull, reason: '$state');
    }
  });

  for (final size in [TestSizes.tablet, TestSizes.web]) {
    for (final language in ['en', 'ar']) {
      testWidgets(
        'KIT-T17: on ${size.width.toInt()} px wide in $language the prompt keeps '
        'a readable width at the start edge',
        (tester) async {
          for (final state in PermissionState.values) {
            await pumpApp(
              tester,
              PermissionPrompt(
                permission: AppPermission.notifications,
                state: state,
                onRequest: () {},
                onOpenSettings: () {},
              ),
              language: language,
              size: size,
            );
            expect(tester.takeException(), isNull, reason: '$state');
            final box = tester.getRect(
              find
                  .descendant(
                    of: find.byType(PermissionPrompt),
                    matching: find.byType(AnimatedSwitcher),
                  )
                  .first,
            );
            expect(
              box.width,
              lessThanOrEqualTo(AppDimensions.dialogMaxWidth),
              reason: '$state',
            );
            if (language == 'ar') {
              expect(box.right, closeTo(size.width, 0.5), reason: '$state');
            } else {
              expect(box.left, closeTo(0, 0.5), reason: '$state');
            }
          }
        },
      );
    }
  }

  for (final language in ['en', 'ar']) {
    testWidgets(
      'KIT-T17: on the web a refused permission asks for the browser settings '
      'in $language, with no button',
      (tester) async {
        const web = PlatformCapabilities(
          isWeb: true,
          platform: TargetPlatform.iOS,
        );
        final l10n = l10nFor(language);
        var opened = 0;
        for (final state in [
          PermissionState.denied,
          PermissionState.permanentlyDenied,
          PermissionState.revoked,
        ]) {
          await pumpApp(
            tester,
            PermissionPrompt(
              permission: AppPermission.camera,
              state: state,
              canOpenSettings: web.appSettingsPage,
              onRequest: () {},
              onOpenSettings: () => opened++,
            ),
            language: language,
            size: TestSizes.web,
          );
          expect(
            find.text(l10n.permissionBrowserBody),
            findsOneWidget,
            reason: '$state',
          );
          expect(find.byType(AppButton), findsNothing, reason: '$state');
          expect(find.text(l10n.permissionOpenSettings), findsNothing);
          expect(find.text(l10n.permissionAllow), findsNothing);
        }
        expect(opened, 0);
        // Not asked yet: asking still works on the web.
        await pumpApp(
          tester,
          PermissionPrompt(
            permission: AppPermission.camera,
            state: PermissionState.notAsked,
            canOpenSettings: web.appSettingsPage,
            onRequest: () {},
            onOpenSettings: () {},
          ),
          language: language,
          size: TestSizes.web,
        );
        expect(find.text(l10n.permissionAllow), findsOneWidget);
      },
    );
  }
}
