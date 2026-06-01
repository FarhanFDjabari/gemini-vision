import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/core/config/model_config.dart';
import 'package:gemini_vision/env.dart';

/// [InferenceService] backed by the `flutter_gemma` plugin running a Gemma
/// LiteRT-LM model fully on-device.
class GemmaInferenceService implements InferenceService {
  InferenceModel? _model;
  CancelToken? _downloadCancelToken;

  @override
  Future<bool> isModelInstalled() {
    return FlutterGemma.isModelInstalled(ModelConfig.fileName);
  }

  @override
  Future<void> downloadModel({
    required void Function(int progress) onProgress,
  }) async {
    final cancelToken = CancelToken();
    _downloadCancelToken = cancelToken;
    try {
      // Show a system progress notification so the user can track the download
      // (and the foreground-service download) without keeping the app open.
      await _configureDownloadNotification();

      // install() is idempotent: it downloads when missing (emitting progress)
      // and always marks the model active for inference. The plugin retries
      // transient network errors with backoff; `foreground: true` runs an
      // Android foreground service so the download survives app backgrounding.
      await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          )
          .fromNetwork(
            ModelConfig.downloadUrl,
            token: Env.huggingFaceToken.isEmpty ? null : Env.huggingFaceToken,
            foreground: true,
          )
          .withProgress(onProgress)
          .withCancelToken(cancelToken)
          .install();
    } on DownloadCancelledException {
      throw const InferenceCancelledException();
    } on Exception catch (e) {
      throw InferenceException('Failed to download model: $e');
    } finally {
      _downloadCancelToken = null;
    }
  }

  @override
  void cancelDownload() {
    _downloadCancelToken?.cancel('User cancelled the model download');
  }

  /// Registers a system notification (with a progress bar on Android) for the
  /// background download task the plugin runs via `background_downloader`. The
  /// `FileDownloader` singleton is shared with the plugin, so configuring it
  /// here applies to the model download. Requests the Android 13+ notification
  /// permission first; the download still proceeds if it is denied.
  Future<void> _configureDownloadNotification() async {
    final downloader = FileDownloader();
    if (await downloader.permissions.status(PermissionType.notifications) !=
        PermissionStatus.granted) {
      await downloader.permissions.request(PermissionType.notifications);
    }
    downloader.configureNotification(
      running: const TaskNotification(
        'Downloading vision model',
        'Download in progress: {progress}',
      ),
      complete: const TaskNotification(
        'Vision model ready',
        'The on-device model finished downloading.',
      ),
      error: const TaskNotification(
        'Download interrupted',
        'Open the app to resume the model download.',
      ),
      canceled: const TaskNotification(
        'Download canceled',
        'The model download was canceled.',
      ),
      progressBar: true,
    );
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
  Future<void> deleteModel() async {
    await _model?.close();
    _model = null;
    try {
      await FlutterGemma.uninstallModel(ModelConfig.fileName);
    } on Exception {
      // Nothing usable to remove (e.g. metadata already gone); a fresh
      // download will overwrite any leftover file regardless.
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
