import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Studio Bipolar Rotary Dial for Master 4-Band EQ (-20 dB to +20 dB).
/// Raw value is 0..40 where 20 represents 0 dB center detent.
/// Drag vertically to adjust; double tap resets to 0 dB.
class MasterEqDial extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const MasterEqDial({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MasterEqDial> createState() => _MasterEqDialState();
}

class _MasterEqDialState extends State<MasterEqDial> {
  double _dragStartY = 0;
  int _startValue = 20;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final val = widget.value.clamp(0, 40);
    final db = val - 20;

    // Detent color logic: +dB Amber, -dB Cyan, 0dB Neutral
    final Color detentColor = db > 0
        ? const Color(0xFFFF9800)
        : (db < 0 ? const Color(0xFF00ADB5) : colors.textPrimary);

    final dbText = '${db > 0 ? '+' : ''}$db dB';

    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _startValue = val;
      },
      onVerticalDragUpdate: (details) {
        final deltaY = _dragStartY - details.globalPosition.dy;
        final deltaValue = (deltaY / 120 * 40).round();
        final newVal = (_startValue + deltaValue).clamp(0, 40);
        if (newVal != val) {
          widget.onChanged(newVal);
        }
      },
      onDoubleTap: () => widget.onChanged(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: CustomPaint(
              painter: _EqDialPainter(
                value: val,
                detentColor: detentColor,
                isDark: colors.isDark,
              ),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: colors.isDark
                          ? const [Color(0xFF2C2C3E), Color(0xFF161622)]
                          : const [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: db != 0 ? detentColor.withValues(alpha: 0.6) : colors.borderSubtle,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: detentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: detentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: detentColor.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Text(
              dbText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: detentColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EqDialPainter extends CustomPainter {
  final int value; // 0..40 (20 = center)
  final Color detentColor;
  final bool isDark;

  _EqDialPainter({
    required this.value,
    required this.detentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);
    const topAngle = -math.pi / 2;

    // Track background arc
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF232334) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Center Detent Tick mark at top (0 dB)
    final tickPaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 2),
      Offset(center.dx, center.dy - radius + 3),
      tickPaint,
    );

    // Active Bipolar Arc
    final db = value - 20;
    if (db != 0) {
      final activePaint = Paint()
        ..color = detentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      // Fraction of sweep from center: db / 20 * (sweepAngle / 2)
      final arcSweep = (db / 20.0) * (sweepAngle / 2.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        topAngle,
        arcSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqDialPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.detentColor != detentColor ||
        oldDelegate.isDark != isDark;
  }
}
