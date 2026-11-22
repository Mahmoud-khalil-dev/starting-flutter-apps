import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// An image the user chose, already resized, ready to upload.
class PickedImage extends Equatable {
  const PickedImage({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String name;
  final String mimeType;

  @override
  List<Object?> get props => [bytes, name, mimeType];
}
