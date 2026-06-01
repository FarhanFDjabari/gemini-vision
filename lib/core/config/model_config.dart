import 'package:gemini_vision/env.dart';

/// Static configuration for the on-device Gemma LiteRT-LM model.
class ModelConfig {
  const ModelConfig._();

  /// Default download location for the multimodal Gemma 4 E2B LiteRT-LM model.
  ///
  /// Override at build time with `--dart-define=MODEL_URL=...` when hosting the
  /// weights elsewhere or pointing at a different quantization.
  static const String defaultDownloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it-int4.litertlm';

  /// Effective download URL, honouring the [Env.modelDownloadUrl] override.
  static String get downloadUrl =>
      Env.modelDownloadUrl.isEmpty ? defaultDownloadUrl : Env.modelDownloadUrl;

  /// Local filename the plugin uses to track the installed model. Must match
  /// the basename of [downloadUrl] so install/lookup stay in sync.
  static String get fileName => Uri.parse(downloadUrl).pathSegments.last;

  /// Maximum context window for the inference session.
  static const int maxTokens = 2048;

  /// Prompt sent alongside the captured image.
  static const String visionPrompt =
      'Act as an assistant for the visually impaired. Explain the content of '
      'the image. Make it simple to understand.';
}
