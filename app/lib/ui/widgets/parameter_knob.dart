import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/effect_parameter.dart';

class ParameterKnob extends StatefulWidget {
  final EffectParameter parameter;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const ParameterKnob({
    super.key,
    required this.parameter,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<ParameterKnob> createState() => _ParameterKnobState();
}

class _ParameterKnobState extends State<ParameterKnob> {
  double _dragStartY = 0;
  int _startValue = 0;

  @override
  Widget build(BuildContext context) {
    final param = widget.parameter;
    final normalized = (param.value - param.min) / (param.max - param.min);

    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
        _startValue = param.value;
      },
      onVerticalDragUpdate: (details) {
        final deltaY = _dragStartY - details.globalPosition.dy;
        // Sensitivity: 150px drag spans full 0..100 range
        final range = param.max - param.min;
        final deltaValue = (deltaY / 150 * range).round();
        final newValue = (_startValue + deltaValue).clamp(param.min, param.max);
        if (newValue != param.value) {
          widget.onChanged(newValue);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Knob Dial
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: _KnobPainter(
                value: normalized,
                accentColor: widget.accentColor,
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF2C2C38), Color(0xFF16161E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.white12, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      param.displayOffset != 0 ? param.formattedValue : '${param.value}',
                      style: TextStyle(
                        fontSize: (param.displayOffset != 0 && param.formattedValue.length > 3) ? 12 : 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            param.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 0.8,
            ),
          ),
          if (param.unit.isNotEmpty)
            Text(
              param.unit,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
        ],
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color accentColor;

  _KnobPainter({required this.value, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    const startAngle = 0.75 * math.pi; // ~135 degrees (bottom left)
    const sweepAngle = 1.5 * math.pi;  // ~270 degrees sweep

    // Background track arc
    final trackPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active value arc
    final activePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_KnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.accentColor != accentColor;
}
