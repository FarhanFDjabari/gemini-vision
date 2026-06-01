import 'dart:typed_data';

/// Raised when the on-device model fails to download, load, or generate.
class InferenceException implements Exception {
  const InferenceException(this.message);

  final String message;

  @override
  String toString() => 'InferenceException: $message';
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
  /// No-op beyond activation when the model is already installed.
  Future<void> downloadModel({required void Function(int progress) onProgress});

  /// Ensures the model is loaded into memory and ready for inference.
  Future<void> ensureLoaded();

  /// Generates a caption for the given image bytes using [prompt].
  Future<String> generateCaption({
    required Uint8List imageBytes,
    required String prompt,
  });

  /// Releases the loaded model and any native resources.
  Future<void> dispose();
}
