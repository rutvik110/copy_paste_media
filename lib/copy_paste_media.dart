import 'dart:typed_data';

import 'copy_paste_media_platform_interface.dart';

class CopyPasteMedia {
  Future<String?> getPlatformVersion() {
    return CopyPasteMediaPlatform.instance.getPlatformVersion();
  }

  /// Copies [imageBase64] (image bytes, base64-encoded) onto the system
  /// clipboard.
  Future<void> copyImage(String imageBase64) {
    return CopyPasteMediaPlatform.instance.copyImage(imageBase64);
  }

  /// Reads the image from the system clipboard.
  ///
  /// Returns image bytes, or `null` when the clipboard has no image (plain
  /// text, empty, or an unsupported type).
  Future<Uint8List?> pasteImage() {
    return CopyPasteMediaPlatform.instance.pasteImage();
  }
}
