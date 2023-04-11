import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'copyimageflutter_method_channel.dart';

abstract class CopyimageflutterPlatform extends PlatformInterface {
  /// Constructs a CopyimageflutterPlatform.
  CopyimageflutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static CopyimageflutterPlatform _instance = MethodChannelCopyimageflutter();

  /// The default instance of [CopyimageflutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelCopyimageflutter].
  static CopyimageflutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CopyimageflutterPlatform] when
  /// they register themselves.
  static set instance(CopyimageflutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> copyImage(String imageBase64) {
    throw UnimplementedError('copyImage has not been implemented.');
  }
}
