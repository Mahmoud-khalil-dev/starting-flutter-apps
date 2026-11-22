import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_upload_state.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/widgets/app_avatar_upload.dart';

import '../../helpers/pump_app.dart';

// A one-pixel PNG, in memory: the tests carry no image files.
final _image = PickedImage(
  bytes: Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]),
  name: 'me.png',
  mimeType: 'image/png',
);

void main() {
  Widget upload(
    AvatarUploadState state, {
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
    VoidCallback? onAllow,
    bool canOpenSettings = true,
  }) => AppAvatarUpload(
    name: 'Sara Ali',
    state: state,
    canUseCamera: true,
    onChoose: (_) {},
    onAllow: onAllow ?? () {},
    onRetry: onRetry ?? () {},
    onOpenSettings: onOpenSettings ?? () {},
    canOpenSettings: canOpenSettings,
  );

  for (final size in [TestSizes.phone, TestSizes.tablet, TestSizes.web]) {
    for (final brightness in Brightness.values) {
      testWidgets('KIT-T18: uploading shows Arabic-Indic progress at '
          '${size.width.toInt()} ${brightness.name}', (tester) async {
        await pumpApp(
          tester,
          upload(
            AvatarUploadState(
              status: AvatarUploadStatus.uploading,
              percent: 40,
              image: _image,
            ),
          ),
          language: 'ar',
          size: size,
          brightness: brightness,
          settle: false,
        );
        expect(find.text('جارٍ الرفع، ٤٠٪'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('KIT-T18: uploading says its percent in English too', (
    tester,
  ) async {
    await pumpApp(
      tester,
      upload(
        AvatarUploadState(
          status: AvatarUploadStatus.uploading,
          percent: 7,
          image: _image,
        ),
      ),
      settle: false,
    );
    expect(find.text('Uploading, 7%'), findsOneWidget);
  });

  testWidgets('KIT-T18: the avatar cannot be changed while uploading', (
    tester,
  ) async {
    await pumpApp(
      tester,
      upload(
        AvatarUploadState(status: AvatarUploadStatus.uploading, image: _image),
      ),
      settle: false,
    );
    await tester.tap(find.bySemanticsLabel('Change your photo'));
    await tester.pump();
    expect(find.text('Choose from your photos'), findsNothing);
  });

  testWidgets('KIT-T18: a failed upload offers a retry', (tester) async {
    var retried = 0;
    await pumpApp(
      tester,
      upload(
        AvatarUploadState(
          status: AvatarUploadStatus.failed,
          image: _image,
          failure: const NoConnection(),
        ),
        onRetry: () => retried++,
      ),
    );
    expect(find.text('Your photo could not be uploaded.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('KIT-T18: the camera explains itself, then allows', (
    tester,
  ) async {
    var allowed = 0;
    await pumpApp(
      tester,
      upload(
        const AvatarUploadState(
          status: AvatarUploadStatus.needsPermission,
          permission: PermissionState.notAsked,
        ),
        onAllow: () => allowed++,
      ),
    );
    expect(
      find.text('Allow camera access to take your profile photo.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Allow'));
    expect(allowed, 1);
  });

  testWidgets('KIT-T18: a refused camera points to Settings', (tester) async {
    var opened = 0;
    await pumpApp(
      tester,
      upload(
        const AvatarUploadState(
          status: AvatarUploadStatus.needsPermission,
          permission: PermissionState.permanentlyDenied,
        ),
        onOpenSettings: () => opened++,
      ),
    );
    await tester.tap(find.text('Open Settings'));
    expect(opened, 1);
  });

  testWidgets('KIT-T18: on the web a refused camera has no button', (
    tester,
  ) async {
    await pumpApp(
      tester,
      upload(
        const AvatarUploadState(
          status: AvatarUploadStatus.needsPermission,
          permission: PermissionState.permanentlyDenied,
        ),
        canOpenSettings: false,
      ),
      web: true,
    );
    expect(find.text('Open Settings'), findsNothing);
    expect(find.textContaining('site settings'), findsOneWidget);
  });

  testWidgets('KIT-T18: the sheet offers the camera only where there is one', (
    tester,
  ) async {
    ImageOrigin? chosen;
    await pumpApp(
      tester,
      AppAvatarUpload(
        name: 'Sara Ali',
        state: const AvatarUploadState(),
        canUseCamera: false,
        onChoose: (origin) => chosen = origin,
        onAllow: () {},
        onRetry: () {},
        onOpenSettings: () {},
      ),
    );
    await tester.tap(find.bySemanticsLabel('Change your photo'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsNothing);
    await tester.tap(find.text('Choose from your photos'));
    await tester.pumpAndSettle();
    expect(chosen, ImageOrigin.gallery);
  });

  testWidgets('KIT-T18: the sheet offers the camera on a phone', (
    tester,
  ) async {
    ImageOrigin? chosen;
    await pumpApp(
      tester,
      AppAvatarUpload(
        name: 'Sara Ali',
        state: const AvatarUploadState(),
        canUseCamera: true,
        onChoose: (origin) => chosen = origin,
        onAllow: () {},
        onRetry: () {},
        onOpenSettings: () {},
      ),
    );
    await tester.tap(find.bySemanticsLabel('Change your photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(chosen, ImageOrigin.camera);
  });

  bool live(WidgetTester tester, Finder finder) => tester
      .getSemantics(finder)
      .getSemanticsData()
      .flagsCollection
      .isLiveRegion;

  testWidgets('KIT-T18: progress is a live region in Arabic-Indic digits', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      upload(
        AvatarUploadState(
          status: AvatarUploadStatus.uploading,
          percent: 47,
          image: _image,
        ),
      ),
      language: 'ar',
      settle: false,
    );
    // Read out in tens, so a screen reader is not told every percent.
    final spoken = find.bySemanticsLabel('جارٍ الرفع، ٤٠٪');
    expect(spoken, findsOneWidget);
    expect(live(tester, spoken), isTrue);
    expect(find.text('جارٍ الرفع، ٤٧٪'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('KIT-T18: a failed upload is announced', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      upload(
        AvatarUploadState(
          status: AvatarUploadStatus.failed,
          image: _image,
          failure: const NoConnection(),
        ),
      ),
    );
    expect(
      live(tester, find.bySemanticsLabel('Your photo could not be uploaded.')),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('KIT-T18: the camera cue shows only where there is a camera', (
    tester,
  ) async {
    Widget avatar({required bool camera, AvatarUploadState? state}) =>
        AppAvatarUpload(
          name: 'Sara Ali',
          state: state ?? const AvatarUploadState(),
          canUseCamera: camera,
          onChoose: (_) {},
          onAllow: () {},
          onRetry: () {},
          onOpenSettings: () {},
        );
    await pumpApp(tester, avatar(camera: false));
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    await pumpApp(tester, avatar(camera: true));
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    await pumpApp(
      tester,
      avatar(
        camera: true,
        state: const AvatarUploadState(
          status: AvatarUploadStatus.uploading,
          percent: 10,
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
  });
}
