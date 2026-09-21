import 'package:copy_paste_media/copy_paste_media.dart';
import 'package:copy_paste_media_example/copy_image_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _sampleAsset = 'assets/sample.jpg';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  Uint8List? _pastedImage;
  String? _pasteStatus;
  final _copyPasteMediaPlugin = CopyPasteMedia();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _copyPasteMediaPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<Uint8List?> _sampleImageBytes() async {
    final data = await rootBundle.load(_sampleAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _pasteImage() async {
    try {
      final bytes = await _copyPasteMediaPlugin.pasteImage();
      setState(() {
        _pastedImage = bytes;
        _pasteStatus = bytes == null
            ? 'Clipboard has no image'
            : 'Pasted ${bytes.length} bytes';
      });
    } on PlatformException catch (error) {
      setState(() {
        _pastedImage = null;
        _pasteStatus = 'Paste failed: ${error.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C6FFF),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copy Paste Media',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Copy the sample image, or paste one from Finder, Preview, or another app.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _platformVersion,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 720;
                      final sample =
                          _SamplePane(onCopyImage: _sampleImageBytes);
                      final clipboard = _ClipboardPane(
                        bytes: _pastedImage,
                        status: _pasteStatus,
                        onPaste: _pasteImage,
                      );
                      if (stacked) {
                        return Column(
                          children: [
                            Expanded(child: sample),
                            const SizedBox(height: 16),
                            Expanded(child: clipboard),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: sample),
                          const SizedBox(width: 20),
                          Expanded(child: clipboard),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SamplePane extends StatelessWidget {
  const _SamplePane({required this.onCopyImage});

  final Future<Uint8List?> Function() onCopyImage;

  @override
  Widget build(BuildContext context) {
    return _PaneCard(
      title: 'Sample image',
      subtitle: 'Bundled Flutter asset',
      action: CopyImageButton(onCopyImage: onCopyImage),
      child: Image.asset(
        _sampleAsset,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ClipboardPane extends StatelessWidget {
  const _ClipboardPane({
    required this.onPaste,
    this.bytes,
    this.status,
  });

  final Uint8List? bytes;
  final String? status;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return _PaneCard(
      title: 'Clipboard',
      subtitle: status ?? 'Nothing pasted yet',
      action: FilledButton.tonalIcon(
        onPressed: onPaste,
        icon: const Icon(Icons.paste),
        label: const Text('Paste image'),
      ),
      child: bytes == null
          ? Center(
              child: Text(
                'Paste an image to preview it here',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : Image.memory(
              bytes!,
              key: ValueKey<int>(
                Object.hash(bytes!.length, bytes!.first, bytes!.last),
              ),
              fit: BoxFit.contain,
              gaplessPlayback: false,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Could not decode image'));
              },
            ),
    );
  }
}

class _PaneCard extends StatelessWidget {
  const _PaneCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                action,
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox.expand(child: child),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
