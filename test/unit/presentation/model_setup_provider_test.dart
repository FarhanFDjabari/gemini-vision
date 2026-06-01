import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_vision/core/ai/gemma_inference_service.dart';
import 'package:gemini_vision/core/ai/inference_service.dart';
import 'package:gemini_vision/presentation/providers/model_setup_provider.dart';
import 'package:gemini_vision/presentation/providers/model_setup_state.dart';

import '../../fakes/fake_inference_service.dart';

Future<void> _settle(ProviderContainer container, {int maxTicks = 50}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    final state = container.read(modelSetupProvider);
    if (state is ModelSetupReady || state is ModelSetupError) return;
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer _containerFor(FakeInferenceService fake) {
  final container = ProviderContainer(
    overrides: [inferenceServiceProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ModelSetupNotifier', () {
    test(
      'loads immediately and reports ready when model is installed',
      () async {
        final fake = FakeInferenceService(installed: true);
        final container = _containerFor(fake);

        await _settle(container);

        expect(container.read(modelSetupProvider), isA<ModelSetupReady>());
        expect(fake.downloadCalled, isFalse);
        expect(fake.ensureLoadedCalls, 1);
      },
    );

    test(
      'downloads with progress then becomes ready when not installed',
      () async {
        final fake = FakeInferenceService(
          installed: false,
          progressSteps: const [10, 60, 100],
        );
        final container = _containerFor(fake);

        final states = <ModelSetupState>[];
        container.listen(
          modelSetupProvider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );

        await _settle(container);

        expect(fake.downloadCalled, isTrue);
        expect(container.read(modelSetupProvider), isA<ModelSetupReady>());

        final progresses = states
            .whereType<ModelSetupDownloading>()
            .map((s) => s.progress)
            .toList();
        expect(progresses, containsAllInOrder(const [10, 60, 100]));
      },
    );

    test('reports error with message when download fails', () async {
      final fake = FakeInferenceService(
        installed: false,
        downloadError: const InferenceException('network down'),
      );
      final container = _containerFor(fake);

      await _settle(container);

      final state = container.read(modelSetupProvider);
      expect(state, isA<ModelSetupError>());
      expect((state as ModelSetupError).message, 'network down');
    });

    test(
      're-downloads when an installed model fails to load',
      () async {
        final fake = FakeInferenceService(
          installed: true,
          loadError: const InferenceException(
            'Active model is no longer installed',
          ),
        );
        final container = _containerFor(fake);

        await _settle(container);

        expect(container.read(modelSetupProvider), isA<ModelSetupReady>());
        expect(fake.deleteCalled, isTrue);
        expect(fake.downloadCalled, isTrue);
        expect(fake.ensureLoadedCalls, 2);
      },
    );

    test('retry recovers after a transient failure', () async {
      final fake = FakeInferenceService(
        installed: false,
        downloadError: const InferenceException('temporary'),
      );
      final container = _containerFor(fake);

      await _settle(container);
      expect(container.read(modelSetupProvider), isA<ModelSetupError>());

      fake.downloadError = null;
      await container.read(modelSetupProvider.notifier).retry();
      await _settle(container);

      expect(container.read(modelSetupProvider), isA<ModelSetupReady>());
    });
  });
}
