import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
    return AspectRatio(
      aspectRatio: MediaQuery.sizeOf(context).aspectRatio,
      child: CameraPreview(
        widget.controller,
        child: widget.isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : null,
      ),
    );
  }
}
