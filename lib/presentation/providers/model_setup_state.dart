sealed class ModelSetupState {
  const ModelSetupState();
}

/// Verifying whether the model is already present on the device.
class ModelSetupChecking extends ModelSetupState {
  const ModelSetupChecking();
}

/// Downloading the model weights. [progress] is a percentage (0-100).
class ModelSetupDownloading extends ModelSetupState {
  const ModelSetupDownloading(this.progress);

  final int progress;
}

/// Model is downloaded, loaded, and ready for inference.
class ModelSetupReady extends ModelSetupState {
  const ModelSetupReady();
}

/// Setup failed; [message] describes the failure.
class ModelSetupError extends ModelSetupState {
  const ModelSetupError(this.message);

  final String message;
}
