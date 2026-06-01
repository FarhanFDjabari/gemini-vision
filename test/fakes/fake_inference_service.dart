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
    this.cancelDuringDownload = false,
  });

  bool installed;
  List<int> progressSteps;
  Object? downloadError;
  Object? loadError;
  String caption;

  bool downloadCalled = false;
  bool deleteCalled = false;
  bool cancelCalled = false;
  int ensureLoadedCalls = 0;
  Uint8List? lastImageBytes;
  String? lastPrompt;

  /// When true, [downloadModel] throws [InferenceCancelledException] after
  /// emitting the first progress step, simulating a cancellation mid-download.
  bool cancelDuringDownload;

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
      if (cancelDuringDownload) {
        throw const InferenceCancelledException();
      }
    }
    installed = true;
  }

  @override
  void cancelDownload() {
    cancelCalled = true;
  }

  @override
  Future<void> ensureLoaded() async {
    ensureLoadedCalls++;
    if (loadError != null) {
      throw loadError!;
    }
  }

  @override
  Future<void> deleteModel() async {
    deleteCalled = true;
    installed = false;
    loadError = null;
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
