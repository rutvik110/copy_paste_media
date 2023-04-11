import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'copyimageflutter_platform_interface.dart';

/// An implementation of [CopyimageflutterPlatform] that uses method channels.
class MethodChannelCopyimageflutter extends CopyimageflutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('copyimageflutter');

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
}
