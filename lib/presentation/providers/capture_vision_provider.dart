import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/core/repository/app_repository.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_state.dart';
import 'package:logging/logging.dart';

class CaptureVisionNotifier
    extends AutoDisposeAsyncNotifier<CaptureVisionState> {
  @override
  FutureOr<CaptureVisionState> build() {
    return CaptureVisionInitial();
  }

  Future<void> captureVision(XFile xFile) async {
    state = const AsyncValue.loading();
    final repository = ref.read(repositoryProvider);

    try {
      final buffer = StringBuffer();
      await for (final chunk in repository.getCaption(xFile)) {
        buffer.write(chunk);
        state = AsyncValue.data(CaptureVisionStreaming(buffer.toString()));
      }
      state = AsyncValue.data(CaptureVisionLoaded(buffer.toString()));
    } on InferenceException catch (e, stackTrace) {
      log(
        e.toString(),
        name: 'CaptureVisionNotifierError',
        level: Level.SEVERE.value,
      );
      state = AsyncValue.error(CaptureVisionError(e.message), stackTrace);
    } on Exception catch (e, stackTrace) {
      log(
        e.toString(),
        name: 'CaptureVisionNotifierError',
        level: Level.SEVERE.value,
      );
      state = AsyncValue.error(
        CaptureVisionError('Unknown error occurred'),
        stackTrace,
      );
    }
  }
}

final captureVisionProvider =
    AsyncNotifierProvider.autoDispose<
      CaptureVisionNotifier,
      CaptureVisionState
    >(CaptureVisionNotifier.new);
