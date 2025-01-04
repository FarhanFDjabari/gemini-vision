sealed class CaptureVisionState {}

class CaptureVisionInitial extends CaptureVisionState {}

class CaptureVisionLoading extends CaptureVisionState {}

class CaptureVisionLoaded extends CaptureVisionState {
  final String data;

  CaptureVisionLoaded(this.data);
}

class CaptureVisionError extends CaptureVisionState {
  final String message;

  CaptureVisionError(this.message);
}
