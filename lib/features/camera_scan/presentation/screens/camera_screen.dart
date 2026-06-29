import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../product_analysis/application/providers/product_analysis_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).noCamera;
          _isInitializing = false;
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final analysisState = ref.watch(productAnalysisControllerProvider);
    final isBusy = _isCapturing || analysisState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cameraTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: _buildPreview(context, l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: isBusy ? null : _captureAndAnalyze,
                    icon: isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: Text(isBusy ? l10n.analyzing : l10n.captureProduct),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AppLocalizations l10n) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(child: Text(l10n.cameraPlaceholder));
    }
    return CameraPreview(controller);
  }

  Future<void> _captureAndAnalyze() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final image = await controller.takePicture();
      final report = await ref
          .read(productAnalysisControllerProvider.notifier)
          .analyzeImage(image.path);
      if (!mounted) {
        return;
      }
      context.goNamed(RouteNames.report, extra: report);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }
}
