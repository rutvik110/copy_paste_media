# Copy Paste Media

Copy images **to** the macOS clipboard, and paste images **from** it, in a
Flutter desktop app. Currently supports only macOS.

## Usage

```dart
import 'package:copy_paste_media/copy_paste_media.dart';

final clipboard = CopyPasteMedia();

// Copy PNG/JPEG bytes (base64) onto the pasteboard.
await clipboard.copyImage(base64Encode(pngBytes));

// Read the first clipboard image as PNG bytes.
final pasted = await clipboard.pasteImage();
if (pasted != null) {
  // Image.memory(pasted)
}
```

`pasteImage` returns `null` when the clipboard has no image (text, empty, or
an unsupported type). It accepts PNG, TIFF, JPEG, HEIC, and Finder file URLs.
