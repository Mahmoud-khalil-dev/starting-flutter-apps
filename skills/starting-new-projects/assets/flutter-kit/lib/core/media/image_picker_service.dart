import 'package:kit_app/core/media/picked_image.dart';

enum ImageOrigin { camera, gallery }

/// Null when the user cancels. Ask camera permission first, through
/// `Permissions`; the gallery needs none (the system picker).
abstract interface class ImagePickerService {
  Future<PickedImage?> pick(ImageOrigin origin);
}
