import 'dart:typed_data';

/// Raised when the on-device model fails to download, load, or generate.
class InferenceException implements Exception {
  const InferenceException(this.message);

  final String message;

  @override
  String toString() => 'InferenceException: $message';
}

/// Raised when an in-progress [InferenceService.downloadModel] is cancelled via
/// [InferenceService.cancelDownload]. Distinct from [InferenceException] so the
/// UI can treat a user cancellation as a normal outcome rather than a failure.
class InferenceCancelledException implements Exception {
  const InferenceCancelledException();

  @override
  String toString() => 'InferenceCancelledException';
}

/// Boundary around the on-device LiteRT-LM model lifecycle and inference.
///
/// Keeping this behind an interface lets the rest of the app (repository,
/// providers) depend on a plain Dart contract that is trivial to fake in tests
/// without pulling in the native plugin.
abstract interface class InferenceService {
  /// Whether the model weights are already present on the device.
  Future<bool> isModelInstalled();

  /// Downloads the model, reporting progress as an integer percentage (0-100).
  ///
  /// Runs in a background-capable download that survives transient network
  /// errors (retried with backoff) and app backgrounding. No-op beyond
  /// activation when the model is already installed.
  ///
  /// Throws [InferenceCancelledException] when interrupted by [cancelDownload].
  Future<void> downloadModel({required void Function(int progress) onProgress});

  /// Cancels an in-progress [downloadModel] call, stopping the underlying
  /// download task so it does not keep running in the background.
  void cancelDownload();

  /// Ensures the model is loaded into memory and ready for inference.
  Future<void> ensureLoaded();

  /// Removes the installed model metadata and files from the device.
  ///
  /// Used to clear a corrupt or partially downloaded model so it can be
  /// re-downloaded from scratch.
  Future<void> deleteModel();

  /// Generates a caption for the given image bytes using [prompt].
  Future<String> generateCaption({
    required Uint8List imageBytes,
    required String prompt,
  });

  /// Releases the loaded model and any native resources.
  Future<void> dispose();
}
