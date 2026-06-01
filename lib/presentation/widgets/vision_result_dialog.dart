import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/tts/tts_service.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_provider.dart';
import 'package:gemini_vision/presentation/providers/capture_vision_state.dart';

/// Shows the caption as it streams in (typing effect) and reads it aloud,
/// enqueuing each completed sentence to text-to-speech as it arrives.
class VisionResultDialog extends ConsumerStatefulWidget {
  const VisionResultDialog({super.key});

  @override
  ConsumerState<VisionResultDialog> createState() => _VisionResultDialogState();
}

class _VisionResultDialogState extends ConsumerState<VisionResultDialog> {
  /// Index up to which the caption has already been handed to TTS.
  int _spokenIndex = 0;

  /// Captured in [initState] so it stays usable in [dispose], where `ref` is
  /// no longer valid.
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    // React to streamed tokens by enqueuing newly completed sentences. Done in
    // a listener (not build) so speech is a side effect, not a render concern.
    ref.listenManual(
      captureVisionProvider,
      (_, next) => _handleState(next.valueOrNull),
    );
    // Handle whatever is already present, covering a stream that finished
    // before this listener was registered.
    _handleState(ref.read(captureVisionProvider).valueOrNull);
  }

  void _handleState(CaptureVisionState? visionState) {
    if (visionState is CaptureVisionStreaming) {
      _enqueueCompletedSentences(visionState.partialText);
    } else if (visionState is CaptureVisionLoaded) {
      _enqueueRemainder(visionState.data);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _enqueueCompletedSentences(String text) {
    final boundary = _lastSentenceBoundary(text, _spokenIndex);
    if (boundary <= _spokenIndex) {
      return;
    }
    final chunk = text.substring(_spokenIndex, boundary);
    _spokenIndex = boundary;
    _tts.enqueue(chunk);
  }

  void _enqueueRemainder(String text) {
    if (_spokenIndex < text.length) {
      _tts.enqueue(text.substring(_spokenIndex));
      _spokenIndex = text.length;
    }
  }

  /// Returns the index just past the last sentence terminator at or after
  /// [from], or [from] when no complete sentence is available yet.
  int _lastSentenceBoundary(String text, int from) {
    var boundary = from;
    for (var i = from; i < text.length; i++) {
      final char = text[i];
      if (char == '.' || char == '!' || char == '?' || char == '\n') {
        boundary = i + 1;
      }
    }
    return boundary;
  }

  Future<void> _replay(String text) => _tts.speak(text);

  Future<void> _stop() => _tts.stop();

  @override
  Widget build(BuildContext context) {
    final visionState = ref.watch(captureVisionProvider).valueOrNull;
    final (text, isComplete) = switch (visionState) {
      CaptureVisionStreaming(:final partialText) => (partialText, false),
      CaptureVisionLoaded(:final data) => (data, true),
      _ => ('', false),
    };

    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        // Follow the newest tokens while streaming so the latest text stays in
        // view; once complete, leave scrolling to the user.
        if (!isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.jumpTo(
                scrollController.position.maxScrollExtent,
              );
            }
          });
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Grab handle to signal the sheet can be dragged.
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Vision',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    if (isComplete)
                      _SpeakButton(
                        onReplay: () => _replay(text),
                        onStop: _stop,
                      ),
                  ],
                ),
              ),
              // The result scrolls so long captions stay fully readable; the
              // sheet's controller is attached so dragging the text expands it.
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: text),
                        if (!isComplete)
                          const WidgetSpan(child: _BlinkingCursor()),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isComplete
                          ? () {
                              _stop();
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Toggles between replay and stop, mirroring the live TTS speaking state.
class _SpeakButton extends ConsumerWidget {
  const _SpeakButton({required this.onReplay, required this.onStop});

  final VoidCallback onReplay;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpeaking = ref.watch(ttsServiceProvider).isSpeaking;
    return ValueListenableBuilder<bool>(
      valueListenable: isSpeaking,
      builder: (context, speaking, _) {
        return IconButton(
          tooltip: speaking ? 'Stop' : 'Read aloud',
          icon: Icon(speaking ? Icons.stop_circle : Icons.volume_up),
          onPressed: speaking ? onStop : onReplay,
        );
      },
    );
  }
}

/// Thin blinking caret shown at the end of the text while it streams in.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          '▍',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
