import 'dart:typed_data';

import 'package:copy_paste_media/copy_paste_media.dart';
import 'package:copy_paste_media/copy_paste_media_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeCopyPasteMediaPlatform
    with MockPlatformInterfaceMixin
    implements CopyPasteMediaPlatform {
  String? lastCopied;
  Uint8List? nextPaste;

  @override
  Future<void> copyImage(String imageBase64) async {
    lastCopied = imageBase64;
  }

  @override
  Future<Uint8List?> pasteImage() async => nextPaste;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCopyPasteMediaPlatform fake;

  setUp(() {
    fake = _FakeCopyPasteMediaPlatform();
    CopyPasteMediaPlatform.instance = fake;
  });

  test('copyImage sends base64 to the platform', () async {
    await CopyPasteMedia.copyImage('abc');
    expect(fake.lastCopied, 'abc');
  });

  test('pasteImage returns platform bytes', () async {
    fake.nextPaste = Uint8List.fromList([1, 2, 3]);
    final bytes = await CopyPasteMedia.pasteImage();
    expect(bytes, Uint8List.fromList([1, 2, 3]));
  });

  test('pasteImage returns null when clipboard has no image', () async {
    fake.nextPaste = null;
    expect(await CopyPasteMedia.pasteImage(), isNull);
  });
}
