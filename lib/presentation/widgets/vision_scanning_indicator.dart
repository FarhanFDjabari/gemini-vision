import 'package:flutter/material.dart';

/// Compact pulsing radar indicator used inside the capture button while a
/// caption is generating. Mirrors the look of [VisionScanningOverlay].
class VisionScanningIndicator extends StatefulWidget {
  const VisionScanningIndicator({this.size = 24, super.key});

  final double size;

  @override
  State<VisionScanningIndicator> createState() =>
      _VisionScanningIndicatorState();
}

class _VisionScanningIndicatorState extends State<VisionScanningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulseRingPainter(
              progress: _controller.value,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    // Two expanding rings offset in phase so one is always emerging.
    for (final phase in const [0.0, 0.5]) {
      final t = (progress + phase) % 1.0;
      final radius = maxRadius * (0.25 + t * 0.75);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: (1 - t) * 0.8);
      canvas.drawCircle(center, radius, paint);
    }

    // Solid core dot.
    canvas.drawCircle(center, maxRadius * 0.18, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulseRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
