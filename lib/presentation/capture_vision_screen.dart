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
  late CameraController _cameraController;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _requestPermission();
    _initCamera(1);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    var selectedCamera =
        cameras.elementAtOrNull(selectedCameraIndex) ?? cameras.first;
    _cameraController = CameraController(selectedCamera, ResolutionPreset.max);

    await _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((error) {
      log("Camera error: ${error.toString()}", error: error);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController controller = _cameraController;

    if (!controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _requestPermission();
    }
  }

  Future<void> takePicture() async {
    final result = await _cameraController.takePicture();
    ref.read(captureVisionProvider.notifier).captureVision(result);
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureVisionProvider);
    final statusBarHeight = MediaQuery.viewPaddingOf(context).top;
    ref.listen(
      captureVisionProvider,
      (prev, next) {
        next.when(
          data: (state) {
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
            }
          },
          error: (_, __) {},
          loading: () {},
        );
      },
      onError: (error, stackTrace) {
        log(error.toString(), error: error, stackTrace: stackTrace);
      },
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (_cameraController.value.isInitialized) ...[
            CaptureVisionCameraPreview(
              controller: _cameraController,
              isLoading: captureState.isLoading,
            ),
          ] else ...[
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
          Padding(
            padding:
                EdgeInsets.fromLTRB(16.0, statusBarHeight + 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        int selectedCameraIndex =
                            cameras.indexOf(_cameraController.description);
                        selectedCameraIndex =
                            (selectedCameraIndex + 1) % cameras.length;
                        _initCamera(selectedCameraIndex);
                      },
                      child: Icon(Icons.flip_camera_android_rounded),
                    ),
                  ],
                ),
                FloatingActionButton(
                  shape: CircleBorder(),
                  tooltip: "Take picture",
                  onPressed: captureState.isLoading
                      ? null
                      : () {
                          takePicture();
                        },
                  child: captureState.isLoading
                      ? CircularProgressIndicator()
                      : Icon(Icons.camera_alt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
