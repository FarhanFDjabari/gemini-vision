sealed class CaptureVisionState {}

class CaptureVisionInitial extends CaptureVisionState {}

class CaptureVisionLoading extends CaptureVisionState {}

/// Partial caption emitted while the model is still generating tokens, used to
/// drive the live typing effect in the UI.
class CaptureVisionStreaming extends CaptureVisionState {
  final String partialText;

  CaptureVisionStreaming(this.partialText);
}

class CaptureVisionLoaded extends CaptureVisionState {
  final String data;

  CaptureVisionLoaded(this.data);
}

class CaptureVisionError extends CaptureVisionState {
  final String message;

  CaptureVisionError(this.message);
}
