import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    state = AsyncValue.loading();
    final repository = ref.watch(repositoryProvider);

    try {
      final caption = await repository.getCaption(xFile);
      state = AsyncValue.data(CaptureVisionLoaded(caption));
    } catch (e) {
      log(e.toString(),
          name: 'CaptureVisionNotifierError', level: Level.SEVERE.value);
      if (e is HttpException) {
        state = AsyncValue.error(
          CaptureVisionError("There's an error with the server"),
          StackTrace.current,
        );
      } else {
        state = AsyncValue.error(
          CaptureVisionError("Unknown error occurred"),
          StackTrace.current,
        );
      }
    }
  }
}

final captureVisionProvider = AsyncNotifierProvider.autoDispose<
    CaptureVisionNotifier, CaptureVisionState>(() => CaptureVisionNotifier());
