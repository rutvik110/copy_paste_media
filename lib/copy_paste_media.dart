import 'dart:typed_data';

import 'copy_paste_media_platform_interface.dart';

/// Copy and paste images using the system clipboard.
///
/// Currently supported on macOS only.
///
/// ```dart
/// await CopyPasteMedia.copyImage(base64Encode(bytes));
/// final pasted = await CopyPasteMedia.pasteImage();
/// ```
class CopyPasteMedia {
  CopyPasteMedia._();

  /// Copies [imageBase64] (image bytes, base64-encoded) onto the system
  /// clipboard.
  static Future<void> copyImage(String imageBase64) {
    return CopyPasteMediaPlatform.instance.copyImage(imageBase64);
  }

  /// Reads the image from the system clipboard.
  ///
  /// Returns image bytes, or `null` when the clipboard has no image (plain
  /// text, empty, or an unsupported type).
  static Future<Uint8List?> pasteImage() {
    return CopyPasteMediaPlatform.instance.pasteImage();
  }

  /// The host platform version string, if available.
  static Future<String?> getPlatformVersion() {
    return CopyPasteMediaPlatform.instance.getPlatformVersion();
  }
}
