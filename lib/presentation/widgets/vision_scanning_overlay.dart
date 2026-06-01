import 'package:flutter/material.dart';

/// Animated overlay shown while the on-device model is generating a caption.
///
/// Renders a viewfinder reticle with a sweeping scan line and cycling status
/// messages so the wait reads as the model actively "looking" at the scene.
class VisionScanningOverlay extends StatefulWidget {
  const VisionScanningOverlay({super.key});

  static const List<String> _messages = [
    'Looking at the scene…',
    'Spotting objects…',
    'Reading the details…',
    'Composing a caption…',
  ];

  @override
  State<VisionScanningOverlay> createState() => _VisionScanningOverlayState();
}

class _VisionScanningOverlayState extends State<VisionScanningOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scanController.addStatusListener(_advanceMessageOnCycle);
  }

  void _advanceMessageOnCycle(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _messageIndex =
            (_messageIndex + 1) % VisionScanningOverlay._messages.length;
      });
    }
  }

  @override
  void dispose() {
    _scanController.removeStatusListener(_advanceMessageOnCycle);
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([_scanController, _pulseController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _ScannerPainter(
                    scanProgress: Curves.easeInOut.transform(
                      _scanController.value,
                    ),
                    pulse: _pulseController.value,
                    color: accent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              VisionScanningOverlay._messages[_messageIndex],
              key: ValueKey<int>(_messageIndex),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  _ScannerPainter({
    required this.scanProgress,
    required this.pulse,
    required this.color,
  });

  final double scanProgress;
  final double pulse;
  final Color color;

  static const double _cornerLength = 34;
  static const double _cornerRadius = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bracketPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawCorners(canvas, rect, bracketPaint);

    // Soft glow that breathes with the pulse animation.
    final glowRadius = size.width * (0.32 + pulse * 0.06);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.28 * (0.6 + pulse * 0.4)),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: rect.center, radius: glowRadius));
    canvas.drawCircle(rect.center, glowRadius, glowPaint);

    // Sweeping scan line with a fading trail.
    final clip = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(_cornerRadius),
    );
    canvas.save();
    canvas.clipRRect(clip);

    final scanY = size.height * scanProgress;
    final trailHeight = size.height * 0.35;
    final trailRect = Rect.fromLTWH(
      0,
      scanY - trailHeight,
      size.width,
      trailHeight,
    );
    canvas.drawRect(
      trailRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.22)],
        ).createShader(trailRect),
    );

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(Offset(6, scanY), Offset(size.width - 6, scanY), linePaint);
    canvas.restore();
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    const r = _cornerRadius;
    const l = _cornerLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + r + l)
        ..lineTo(rect.left, rect.top + r)
        ..arcToPoint(
          Offset(rect.left + r, rect.top),
          radius: const Radius.circular(r),
        )
        ..lineTo(rect.left + r + l, rect.top),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - r - l, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(
          Offset(rect.right, rect.top + r),
          radius: const Radius.circular(r),
        )
        ..lineTo(rect.right, rect.top + r + l),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - r - l)
        ..lineTo(rect.right, rect.bottom - r)
        ..arcToPoint(
          Offset(rect.right - r, rect.bottom),
          radius: const Radius.circular(r),
        )
        ..lineTo(rect.right - r - l, rect.bottom),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + r + l, rect.bottom)
        ..lineTo(rect.left + r, rect.bottom)
        ..arcToPoint(
          Offset(rect.left, rect.bottom - r),
          radius: const Radius.circular(r),
        )
        ..lineTo(rect.left, rect.bottom - r - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.color != color;
}
