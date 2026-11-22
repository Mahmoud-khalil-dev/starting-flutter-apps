import 'package:kit_app/core/media/picked_image.dart';

/// The cropping slot. The kit ships [NoCrop]; a project that crops
/// implements this with the cropper it chooses, in `core/platform`, and
/// registers it in `registerMediaModule`. Null means the user cancelled.
abstract interface class ImageCropSlot {
  Future<PickedImage?> crop(PickedImage image);
}

class NoCrop implements ImageCropSlot {
  const NoCrop();

  @override
  Future<PickedImage?> crop(PickedImage image) async => image;
}
