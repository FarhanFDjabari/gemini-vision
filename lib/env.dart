class Env {
  /// Optional HuggingFace access token used to download the gated Gemma
  /// LiteRT-LM model. Provide it at build time with
  /// `--dart-define=HUGGINGFACE_TOKEN=hf_xxx`.
  static const String huggingFaceToken = String.fromEnvironment(
    'HUGGINGFACE_TOKEN',
  );

  /// Override for the model download URL. Falls back to
  /// [ModelConfig.defaultDownloadUrl] when not provided.
  static const String modelDownloadUrl = String.fromEnvironment('MODEL_URL');
}
