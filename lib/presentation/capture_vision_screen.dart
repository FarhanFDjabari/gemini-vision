import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/main.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_provider.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_state.dart';
import 'package:gemini_vision/presentation/widgets/capture_vision_camera_preview.dart';
import 'package:permission_handler/permission_handler.dart';

class CaptureVisionScreen extends ConsumerStatefulWidget {
  const CaptureVisionScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CaptureVisionScreenState();
}

class _CaptureVisionScreenState extends ConsumerState<CaptureVisionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _requestPermission();
    _initCamera(_defaultCameraIndex());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int _defaultCameraIndex() {
    final backIndex = cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    return backIndex == -1 ? 0 : backIndex;
  }

  Future<void> _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Camera permission denied"),
            action: SnackBarAction(
              label: "Open Settings",
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _initCamera(int selectedCameraIndex) async {
    final selectedCamera =
        cameras.elementAtOrNull(selectedCameraIndex) ?? cameras.first;
    _selectedCameraIndex = cameras.indexOf(selectedCamera);

    await _cameraController?.dispose();

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    _cameraController = controller;

    try {
      await controller.initialize();
    } on CameraException catch (error) {
      log("Camera error: ${error.toString()}", error: error);
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller == null || !controller.value.isInitialized) {
        return;
      }
      controller.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      _requestPermission();
      if (_cameraController == null) {
        _initCamera(_selectedCameraIndex);
      }
    }
  }

  Future<void> takePicture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final result = await controller.takePicture();
    ref.read(captureVisionProvider.notifier).captureVision(result);
  }

  /// Freezes the live preview so the camera stream stops competing with the
  /// on-device model for GPU/memory bandwidth while a caption is generated.
  void _pausePreview() {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isPreviewPaused) {
      return;
    }
    unawaited(controller.pausePreview());
  }

  void _resumePreview() {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isPreviewPaused) {
      return;
    }
    unawaited(controller.resumePreview());
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.viewPaddingOf(context).top;
    ref.listen(
      captureVisionProvider,
      (prev, next) {
        next.when(
          data: (state) {
            _resumePreview();
            if (state is CaptureVisionLoaded) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Vision"),
                    content: Text(state.data),
                  );
                },
              );
            } else if (state is CaptureVisionError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          error: (e, __) {
            _resumePreview();
            if (e is CaptureVisionError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.message)));
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          loading: _pausePreview,
        );
      },
      onError: (error, stackTrace) {
        log(error.toString(), error: error, stackTrace: stackTrace);
      },
    );
    final controller = _cameraController;
    final isCameraReady = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (isCameraReady) ...[
            Positioned.fill(
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 1,
                  height: controller.value.previewSize?.width ?? 1,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final captureState = ref.watch(captureVisionProvider);
                      return CaptureVisionCameraPreview(
                        controller: controller,
                        isLoading: captureState.isLoading,
                      );
                    },
                  ),
                ),
              ),
            ),
          ] else ...[
            Center(child: CircularProgressIndicator()),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.0,
              statusBarHeight + 16.0,
              16.0,
              16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final nextIndex =
                            (_selectedCameraIndex + 1) % cameras.length;
                        _initCamera(nextIndex);
                      },
                      child: Icon(Icons.flip_camera_android_rounded),
                    ),
                  ],
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final captureState = ref.watch(captureVisionProvider);
                    return FloatingActionButton(
                      shape: CircleBorder(),
                      tooltip: "Take picture",
                      onPressed: captureState.isLoading
                          ? null
                          : () async {
                              await takePicture();
                            },
                      child: captureState.isLoading
                          ? CircularProgressIndicator()
                          : Icon(Icons.camera_alt),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
