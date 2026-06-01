import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/presentation/capture_vision_screen.dart';
import 'package:gemini_vision/presentation/providers/model_setup_provider.dart';
import 'package:gemini_vision/presentation/providers/model_setup_state.dart';

/// Gate shown at startup. Routes to the camera screen once the on-device model
/// is ready, otherwise surfaces download progress or recoverable errors.
class ModelSetupScreen extends ConsumerWidget {
  const ModelSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelSetupProvider);

    return switch (state) {
      ModelSetupReady() => const CaptureVisionScreen(),
      ModelSetupChecking() => const _SetupScaffold(
        child: _StatusMessage(
          icon: Icons.downloading,
          message: 'Preparing the on-device model…',
        ),
      ),
      ModelSetupDownloading(:final progress) => _SetupScaffold(
        child: _DownloadProgress(progress: progress),
      ),
      ModelSetupError(:final message) => _SetupScaffold(
        child: _SetupError(
          message: message,
          onRetry: () => ref.read(modelSetupProvider.notifier).retry(),
        ),
      ),
    };
  }
}

class _SetupScaffold extends StatelessWidget {
  const _SetupScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(padding: const EdgeInsets.all(32), child: child),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final fraction = (progress.clamp(0, 100)) / 100;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.downloading, size: 48),
        const SizedBox(height: 24),
        Text(
          'Downloading model',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: progress > 0 ? fraction : null),
        const SizedBox(height: 8),
        Text('$progress%'),
        const SizedBox(height: 16),
        const Text(
          'This one-time download may take a few minutes.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SetupError extends StatelessWidget {
  const _SetupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
