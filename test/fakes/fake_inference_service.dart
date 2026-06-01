import 'dart:typed_data';

import 'package:gemini_vision/core/ai/inference_service.dart';

/// Hand-written [InferenceService] fake for driving provider/repository tests.
class FakeInferenceService implements InferenceService {
  FakeInferenceService({
    this.installed = false,
    this.progressSteps = const [25, 50, 100],
    this.downloadError,
    this.loadError,
    this.caption = 'a caption',
  });

  bool installed;
  List<int> progressSteps;
  Object? downloadError;
  Object? loadError;
  String caption;

  bool downloadCalled = false;
  int ensureLoadedCalls = 0;
  Uint8List? lastImageBytes;
  String? lastPrompt;

  @override
  Future<bool> isModelInstalled() async => installed;

  @override
  Future<void> downloadModel({
    required void Function(int progress) onProgress,
  }) async {
    downloadCalled = true;
    if (downloadError != null) {
      throw downloadError!;
    }
    for (final progress in progressSteps) {
      onProgress(progress);
    }
    installed = true;
  }

  @override
  Future<void> ensureLoaded() async {
    ensureLoadedCalls++;
    if (loadError != null) {
      throw loadError!;
    }
  }

  @override
  Future<String> generateCaption({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    lastImageBytes = imageBytes;
    lastPrompt = prompt;
    return caption;
  }

  @override
  Future<void> dispose() async {}
}
