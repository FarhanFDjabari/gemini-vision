import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gemini_vision/presentation/widgets/vision_scanning_overlay.dart';

class CaptureVisionCameraPreview extends StatefulWidget {
  const CaptureVisionCameraPreview({
    required this.controller,
    this.isLoading = false,
    super.key,
  });

  final CameraController controller;
  final bool isLoading;

  @override
  State<CaptureVisionCameraPreview> createState() =>
      _CaptureVisionCameraPreviewState();
}

class _CaptureVisionCameraPreviewState
    extends State<CaptureVisionCameraPreview> {
  @override
  Widget build(BuildContext context) {
    return CameraPreview(
      widget.controller,
      child: widget.isLoading ? const VisionScanningOverlay() : null,
    );
  }
}
