import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/platform/plugin_image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _Picker extends Mock implements ImagePicker {}

void main() {
  late _Picker picker;

  setUpAll(() => registerFallbackValue(ImageSource.gallery));
  setUp(() => picker = _Picker());

  Future<XFile?> Function(Invocation) answer(XFile? file) =>
      (_) async => file;

  void picks(XFile? file) => when(
    () => picker.pickImage(
      source: any(named: 'source'),
      maxWidth: any(named: 'maxWidth'),
      maxHeight: any(named: 'maxHeight'),
      imageQuality: any(named: 'imageQuality'),
      requestFullMetadata: any(named: 'requestFullMetadata'),
    ),
  ).thenAnswer(answer(file));

  test('KIT-T18: the type comes from the file name', () {
    expect(PluginImagePicker.mimeFor('a.PNG'), 'image/png');
    expect(PluginImagePicker.mimeFor('a.webp'), 'image/webp');
    expect(PluginImagePicker.mimeFor('a.heic'), 'image/heic');
    expect(PluginImagePicker.mimeFor('a.jpeg'), 'image/jpeg');
    expect(PluginImagePicker.mimeFor('noext'), 'image/jpeg');
  });

  test('KIT-T18: a pick is resized and keeps no location data', () async {
    picks(
      XFile.fromData(
        Uint8List.fromList([1, 2]),
        name: 'me.png',
        path: 'me.png',
      ),
    );
    final image = await PluginImagePicker(
      picker: picker,
    ).pick(ImageOrigin.camera);
    expect(image!.mimeType, 'image/png');
    expect(image.bytes, [1, 2]);
    verify(
      () => picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      ),
    ).called(1);
  });

  test('KIT-T18: a cancelled pick is null', () async {
    picks(null);
    expect(
      await PluginImagePicker(picker: picker).pick(ImageOrigin.gallery),
      isNull,
    );
  });
}
