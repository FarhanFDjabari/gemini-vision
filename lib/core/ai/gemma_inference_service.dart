import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/core/config/model_config.dart';
import 'package:gemini_vision/env.dart';

/// [InferenceService] backed by the `flutter_gemma` plugin running a Gemma
/// LiteRT-LM model fully on-device.
class GemmaInferenceService implements InferenceService {
  InferenceModel? _model;

  @override
  Future<bool> isModelInstalled() {
    return FlutterGemma.isModelInstalled(ModelConfig.fileName);
  }

  @override
  Future<void> downloadModel({
    required void Function(int progress) onProgress,
  }) async {
    try {
      // install() is idempotent: it downloads when missing (emitting progress)
      // and always marks the model active for inference.
      await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          )
          .fromNetwork(
            ModelConfig.downloadUrl,
            token: Env.huggingFaceToken.isEmpty ? null : Env.huggingFaceToken,
          )
          .withProgress(onProgress)
          .install();
    } on Exception catch (e) {
      throw InferenceException('Failed to download model: $e');
    }
  }

  @override
  Future<void> ensureLoaded() async {
    if (_model != null) return;

    try {
      if (!FlutterGemma.hasActiveModel()) {
        // Model files exist but are not yet active in this process (e.g. after
        // a fresh launch). install() re-activates without re-downloading.
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        ).fromNetwork(ModelConfig.downloadUrl).install();
      }

      _model = await FlutterGemma.getActiveModel(
        maxTokens: ModelConfig.maxTokens,
        supportImage: true,
        maxNumImages: 1,
      );
    } on Exception catch (e) {
      throw InferenceException('Failed to load model: $e');
    }
  }

  @override
  Future<String> generateCaption({
    required Uint8List imageBytes,
    required String prompt,
  }) async {
    await ensureLoaded();
    final model = _model;
    if (model == null) {
      throw const InferenceException('Model is not loaded');
    }

    InferenceModelSession? session;
    try {
      session = await model.createSession(enableVisionModality: true);
      await session.addQueryChunk(
        Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true),
      );
      return await session.getResponse();
    } on Exception catch (e) {
      throw InferenceException('Failed to generate caption: $e');
    } finally {
      await session?.close();
    }
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  final service = GemmaInferenceService();
  ref.onDispose(service.dispose);
  return service;
});
