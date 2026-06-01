import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/ai/gemma_inference_service.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/core/config/model_config.dart';

/// Produces a caption describing the contents of an image.
abstract interface class VisionDataSource {
  Future<String> getCaption(Uint8List imageBytes);
}

/// [VisionDataSource] that delegates to the on-device LiteRT-LM model.
class LiteRtVisionDataSource implements VisionDataSource {
  const LiteRtVisionDataSource(this._inferenceService);

  final InferenceService _inferenceService;

  @override
  Future<String> getCaption(Uint8List imageBytes) {
    return _inferenceService.generateCaption(
      imageBytes: imageBytes,
      prompt: ModelConfig.visionPrompt,
    );
  }
}

final dataSourceProvider = Provider<VisionDataSource>((ref) {
  return LiteRtVisionDataSource(ref.watch(inferenceServiceProvider));
});
