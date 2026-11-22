import 'package:image_picker/image_picker.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/media/picked_image.dart';

class PluginImagePicker implements ImagePickerService {
  PluginImagePicker({
    ImagePicker? picker,
    this.maxSide = 1024,
    this.quality = 85,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final double maxSide;
  final int quality;

  static String mimeFor(String name) {
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  @override
  Future<PickedImage?> pick(ImageOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == ImageOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
      // No location or camera data leaves the device.
      requestFullMetadata: false,
    );
    if (file == null) return null;
    return PickedImage(
      bytes: await file.readAsBytes(),
      name: file.name,
      mimeType: mimeFor(file.name),
    );
  }
}
