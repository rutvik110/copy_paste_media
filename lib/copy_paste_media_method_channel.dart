import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'copy_paste_media_platform_interface.dart';

/// An implementation of [CopyPasteMediaPlatform] that uses method channels.
class MethodChannelCopyPasteMedia extends CopyPasteMediaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('copy_paste_media');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> copyImage(String imageBase64) async {
    await methodChannel.invokeMethod<String>('copyImage', {
      'image': imageBase64,
    });
  }

  @override
  Future<Uint8List?> pasteImage() async {
    final data = await methodChannel.invokeMethod<dynamic>('pasteImage');
    if (data == null) return null;
    if (data is Uint8List) return data;
    if (data is List) return Uint8List.fromList(List<int>.from(data));
    return null;
  }
}
