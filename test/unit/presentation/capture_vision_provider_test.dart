import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/core/data/datasource/vision_datasource.dart';
import 'package:gemini_vision/core/repository/app_repository.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_provider.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_state.dart';

class _StubDataSource implements VisionDataSource {
  @override
  Future<String> getCaption(Uint8List imageBytes) async => '';
}

class _FakeRepository extends AppRepository {
  _FakeRepository({this.caption, this.error})
    : super(datasource: _StubDataSource());

  final String? caption;
  final Object? error;

  @override
  Future<String> getCaption(XFile image) async {
    if (error != null) throw error!;
    return caption ?? '';
  }
}

ProviderContainer _containerFor(AppRepository repository) {
  final container = ProviderContainer(
    overrides: [repositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  // Keep the auto-dispose provider alive for the duration of the test.
  container.listen(captureVisionProvider, (_, __) {});
  return container;
}

void main() {
  final xFile = XFile.fromData(Uint8List(0), name: 'frame.png');

  group('CaptureVisionNotifier', () {
    test('emits loaded state with caption on success', () async {
      final container = _containerFor(_FakeRepository(caption: 'A cat naps.'));

      await container.read(captureVisionProvider.notifier).captureVision(xFile);

      final state = container.read(captureVisionProvider);
      expect(state.value, isA<CaptureVisionLoaded>());
      expect((state.value as CaptureVisionLoaded).data, 'A cat naps.');
    });

    test('surfaces InferenceException message as error state', () async {
      final container = _containerFor(
        _FakeRepository(error: const InferenceException('model crashed')),
      );

      await container.read(captureVisionProvider.notifier).captureVision(xFile);

      final state = container.read(captureVisionProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<CaptureVisionError>());
      expect((state.error as CaptureVisionError).message, 'model crashed');
    });

    test('maps unexpected exceptions to a generic error message', () async {
      final container = _containerFor(
        _FakeRepository(error: const FormatException('boom')),
      );

      await container.read(captureVisionProvider.notifier).captureVision(xFile);

      final state = container.read(captureVisionProvider);
      expect(state.hasError, isTrue);
      expect(
        (state.error as CaptureVisionError).message,
        'Unknown error occurred',
      );
    });
  });
}
