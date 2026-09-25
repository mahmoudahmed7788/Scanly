import 'dart:typed_data';

class PreparedImage {
  final Uint8List bytes;
  final int width;
  final int height;

  const PreparedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });
}