// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:typed_data';

import 'package:copy_paste_media/copy_paste_media.dart';
import 'package:flutter/material.dart';

class CopyImageButton extends StatefulWidget {
  const CopyImageButton({
    required this.onCopyImage,
    super.key,
  });

  final Future<Uint8List?> Function() onCopyImage;

  @override
  State<CopyImageButton> createState() => _CopyImageButtonState();
}

class _CopyImageButtonState extends State<CopyImageButton>
    with SingleTickerProviderStateMixin {
  late bool isCopying;

  late AnimationController animationController;

  late Animation<double> animation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isCopying = false;
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 1),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1, end: 1),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1, end: 0),
        weight: 0.01,
      ),
    ])
        .chain(
          CurveTween(curve: Curves.decelerate),
        )
        .animate(animationController);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: animationController,
          builder: (BuildContext context, Widget? child) {
            return Transform.translate(
              offset: Offset(0, -animation.value * 50),
              child: Container(
                height: animation.value * 25,
                width: animation.value * 25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).colorScheme.primary,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: animation.value * 18,
                ),
              ),
            );
          },
        ),
        FilledButton.icon(
          onPressed: isCopying
              ? null
              : () async {
                  if (animationController.isCompleted) {
                    animationController.reset();
                  }
                  setState(() {
                    isCopying = true;
                  });
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final capturedImageBytes = await widget.onCopyImage();

                    if (capturedImageBytes == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Could not load the sample image'),
                        ),
                      );
                      return;
                    }
                    final String compressedJpegByteDate =
                        base64Encode(capturedImageBytes);

                    final CopyPasteMedia imageCopy = CopyPasteMedia();

                    await imageCopy.copyImage(compressedJpegByteDate);
                    await Future<void>.delayed(
                        const Duration(milliseconds: 100));
                    if (!mounted) return;
                    await animationController.forward();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Image Copied to clipboard'),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        isCopying = false;
                      });
                    }
                  }
                },
          icon: isCopying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Icon(Icons.copy),
          label: Text(isCopying ? 'Copying' : 'Copy sample'),
        ),
      ],
    );
  }
}
