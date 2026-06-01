import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Converts caption text to speech using the platform text-to-speech engine.
///
/// Utterances are spoken sequentially from an internal queue so that caption
/// sentences can be enqueued as they stream in from the model and read aloud
/// in order without overlapping.
class TtsService {
  TtsService(this._tts);

  final FlutterTts _tts;
  final List<String> _queue = [];
  final ValueNotifier<bool> _isSpeaking = ValueNotifier(false);

  bool _configured = false;
  bool _draining = false;
  bool _suspended = false;

  /// Whether speech is currently being produced or pending in the queue.
  ValueListenable<bool> get isSpeaking => _isSpeaking;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    // Makes [FlutterTts.speak] complete only when the utterance finishes, which
    // lets the queue drain one utterance at a time.
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  /// Queues [text] to be spoken after anything already enqueued. Ignored while
  /// suspended (e.g. the app is backgrounded).
  Future<void> enqueue(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _suspended) {
      return;
    }
    await _ensureConfigured();
    _queue.add(trimmed);
    if (!_draining) {
      unawaited(_drain());
    }
  }

  /// Clears the queue and speaks [text] on its own.
  Future<void> speak(String text) async {
    await stop();
    await enqueue(text);
  }

  Future<void> _drain() async {
    _draining = true;
    _isSpeaking.value = true;
    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      await _tts.speak(next);
    }
    _draining = false;
    _isSpeaking.value = false;
  }

  /// Stops any in-progress speech and discards everything still queued.
  Future<void> stop() async {
    _queue.clear();
    await _tts.stop();
    _draining = false;
    _isSpeaking.value = false;
  }

  /// Stops speech and blocks further [enqueue] calls until [resume]. Used to
  /// silence read-along while the app is in the background.
  Future<void> suspend() async {
    _suspended = true;
    await stop();
  }

  void resume() {
    _suspended = false;
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final tts = FlutterTts();
  final service = TtsService(tts);
  ref.onDispose(service.stop);
  return service;
});
