import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/ai/gemma_inference_service.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/presentation/providers/model_setup_state.dart';
import 'package:logging/logging.dart';

/// Drives the startup flow that ensures the on-device model is available:
/// check installation, download with progress when missing, then load it.
class ModelSetupNotifier extends Notifier<ModelSetupState> {
  @override
  ModelSetupState build() {
    _start();
    return const ModelSetupChecking();
  }

  Future<void> _start() async {
    final service = ref.read(inferenceServiceProvider);

    try {
      if (await service.isModelInstalled()) {
        try {
          await service.ensureLoaded();
          state = const ModelSetupReady();
          return;
        } on InferenceException {
          // Metadata reports the model installed, but it failed to load
          // (e.g. a partial/corrupt download). Purge it and re-download once;
          // a second failure falls through to the error state below.
          await service.deleteModel();
        }
      }

      state = const ModelSetupDownloading(0);
      await service.downloadModel(
        onProgress: (progress) => state = ModelSetupDownloading(progress),
      );
      await service.ensureLoaded();
      state = const ModelSetupReady();
    } on InferenceException catch (e) {
      log(e.toString(), name: 'ModelSetupError', level: Level.SEVERE.value);
      state = ModelSetupError(e.message);
    } on Exception catch (e) {
      log(e.toString(), name: 'ModelSetupError', level: Level.SEVERE.value);
      state = ModelSetupError('Failed to prepare the model. Please try again.');
    }
  }

  /// Re-runs the setup flow after a failure.
  Future<void> retry() async {
    state = const ModelSetupChecking();
    await _start();
  }
}

final modelSetupProvider =
    NotifierProvider<ModelSetupNotifier, ModelSetupState>(
      ModelSetupNotifier.new,
    );
