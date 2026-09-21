[![pub package](https://img.shields.io/pub/v/copy_paste_media.svg)](https://pub.dev/packages/copy_paste_media)

Copy and paste images to and from the system clipboard in Flutter.

macOS only. Other platforms are not yet supported. Feel free to contribute support for other platforms.

Demo(macOS): 

https://github.com/user-attachments/assets/e7eaebda-dc02-4819-a0c5-2b282794fe79


## Features

- Copy image from flutter app onto the system clipboard.
- Paste the image from the clipboard.

## Getting started

Add the package to your app:

```yaml
dependencies:
  copy_paste_media: ^0.1.0
```

Then:

```sh
flutter pub get
```

### macOS sandbox

Sandboxed macOS apps need this entitlement to paste an image **file**
from the clipboard.

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

Add it to both `DebugProfile.entitlements` and `Release.entitlements`.

## Usage

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:copy_paste_media/copy_paste_media.dart';
import 'package:flutter/widgets.dart';

// Copy image to the pasteboard.
Future<void> copy(Uint8List imageBytes) async {
  await CopyPasteMedia.copyImage(base64Encode(imageBytes));
}

// Paste the clipboard image, if any.
Future<Image?> paste() async {
  final bytes = await CopyPasteMedia.pasteImage();
  if (bytes == null) return null;
  return Image.memory(bytes);
}
```

`pasteImage` returns `null` when the clipboard has no image (plain text,
empty, or an unsupported type).

A full sample is in the [`example`](example) directory.

Contributions and bug reports are welcome on GitHub.
