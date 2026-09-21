import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'copy_paste_media_method_channel.dart';

abstract class CopyPasteMediaPlatform extends PlatformInterface {
  CopyPasteMediaPlatform() : super(token: _token);

  static final Object _token = Object();

  static CopyPasteMediaPlatform _instance = MethodChannelCopyPasteMedia();

  static CopyPasteMediaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CopyPasteMediaPlatform] when
  /// they register themselves.
  static set instance(CopyPasteMediaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> copyImage(String imageBase64) {
    throw UnimplementedError('copyImage has not been implemented.');
  }

  Future<Uint8List?> pasteImage() {
    throw UnimplementedError('pasteImage has not been implemented.');
  }
}
