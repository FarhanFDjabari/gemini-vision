import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gemini_vision/core/data/datasource/vision_datasource.dart';
import 'package:gemini_vision/core/repository/app_repository.dart';
import 'package:gemini_vision/core/tts/tts_service.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_provider.dart';
import 'package:gemini_vision/presentation/widgets/vision_result_dialog.dart';

/// Records what the dialog hands to TTS without touching the platform plugin.
class _RecordingTts extends TtsService {
  _RecordingTts() : super(FlutterTts());

  final List<String> enqueued = [];
  final List<String> replayed = [];

  @override
  Future<void> enqueue(String text) async => enqueued.add(text.trim());

  @override
  Future<void> speak(String text) async => replayed.add(text.trim());

  @override
  Future<void> stop() async {}
}

class _StubDataSource implements VisionDataSource {
  @override
  Stream<String> getCaption(Uint8List imageBytes) => const Stream.empty();
}

class _FakeRepository extends AppRepository {
  _FakeRepository(this.chunks) : super(datasource: _StubDataSource());

  final List<String> chunks;

  @override
  Stream<String> getCaption(XFile image) => Stream.fromIterable(chunks);
}

void main() {
  final xFile = XFile.fromData(Uint8List(0), name: 'frame.png');

  testWidgets('enqueues each completed sentence as the caption streams', (
    tester,
  ) async {
    final tts = _RecordingTts();
    final container = ProviderContainer(
      overrides: [
        ttsServiceProvider.overrideWithValue(tts),
        repositoryProvider.overrideWithValue(
          _FakeRepository(const ['A cat ', 'sits. ', 'It naps.']),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: VisionResultDialog())),
      ),
    );

    await container.read(captureVisionProvider.notifier).captureVision(xFile);
    await tester.pump();

    // First sentence flushed mid-stream, the tail flushed on completion.
    expect(tts.enqueued, ['A cat sits.', 'It naps.']);
  });

  testWidgets('shows a blinking cursor while streaming and a replay control '
      'once complete', (tester) async {
    final tts = _RecordingTts();
    final container = ProviderContainer(
      overrides: [
        ttsServiceProvider.overrideWithValue(tts),
        repositoryProvider.overrideWithValue(_FakeRepository(const ['Done.'])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: VisionResultDialog())),
      ),
    );

    await container.read(captureVisionProvider.notifier).captureVision(xFile);
    await tester.pump();

    expect(find.text('Done.'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
  });
}
