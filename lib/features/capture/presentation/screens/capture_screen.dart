import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ocr/presentation/providers/ocr_providers.dart';
import '../../../ocr/presentation/screens/ocr_result_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  static const routeName = 'capture';
  static const routePath = '/capture';

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeCameraFuture;
  var _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraFuture = _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '\u062a\u0635\u0648\u064a\u0631 '
            '\u0641\u0627\u062a\u0648\u0631\u0629 \u0623\u0648 '
            '\u0645\u0646\u062a\u062c',
          ),
        ),
        body: FutureBuilder<void>(
          future: _initializeCameraFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || _controller == null) {
              return _CameraError(onRetry: _retryCamera);
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    minimum: const EdgeInsets.all(24),
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _captureAndReadText,
                      icon: _isProcessing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        _isProcessing
                            ? '\u062c\u0627\u0631\u064a '
                                '\u0627\u0644\u062a\u062d\u0644\u064a\u0644'
                            : '\u0627\u0644\u062a\u0642\u0627\u0637 '
                                '\u0627\u0644\u0635\u0648\u0631\u0629',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No cameras available');
    }

    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    _controller = controller;
  }

  void _retryCamera() {
    setState(() {
      _initializeCameraFuture = _initializeCamera();
    });
  }

  Future<void> _captureAndReadText() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final image = await controller.takePicture();
      final result = await ref
          .read(ocrRepositoryProvider)
          .extractTextFromImage(image.path);

      if (!mounted) {
        return;
      }

      context.goNamed(OcrResultScreen.routeName, extra: result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              '\u062a\u0639\u0630\u0631 \u062a\u0634\u063a\u064a\u0644 '
              '\u0627\u0644\u0643\u0627\u0645\u064a\u0631\u0627',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(
                '\u0625\u0639\u0627\u062f\u0629 '
                '\u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
