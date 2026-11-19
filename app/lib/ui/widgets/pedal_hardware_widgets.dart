import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/effect_parameter.dart';

/// Corner Screw Rivet decoration for boutique stompbox pedals
class PedalCornerScrew extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const PedalCornerScrew({super.key, this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF555560),
          border: Border.all(color: Colors.black45, width: 0.5),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 1,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// 3D Jewel LED Indicator for boutique pedal on/off state
class PedalJewelLed extends StatelessWidget {
  final bool active;
  final Color accent;

  const PedalJewelLed({super.key, required this.active, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accent : const Color(0xFF202025),
        border: Border.all(
          color: active ? Colors.white : Colors.white24,
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 3,
                ),
              ]
            : [],
      ),
      child: active
          ? Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}

/// Chrome 3D Metallic Footswitch Button
class PedalChromeFootswitch extends StatelessWidget {
  final bool active;
  final Color accent;

  const PedalChromeFootswitch({super.key, required this.active, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFDCDCDC),
            Color(0xFF888894),
            Color(0xFF484850),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          if (active)
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
        ],
        border: Border.all(color: const Color(0xFF6A6A74), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFA0A0A8),
                Color(0xFF606068),
              ],
            ),
            border: Border.all(color: Colors.black26, width: 1),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF383840),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Set of mini rotary dials for pedal display
class PedalMiniKnobs extends StatelessWidget {
  final List<EffectParameter> params;
  final bool active;
  final Color accent;

  const PedalMiniKnobs({
    super.key,
    required this.params,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (params.isEmpty) {
      return const SizedBox(height: 40);
    }

    final displayParams = params.take(3).toList();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: displayParams.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildSingleKnob(p),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleKnob(EffectParameter param) {
    final normalized = (param.value - param.min) / (param.max - param.min);
    final angle = (-135 + (normalized * 270)) * (math.pi / 180);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF4A4A55), Color(0xFF1E1E24)],
            ),
            border: Border.all(
              color: active ? accent.withValues(alpha: 0.5) : Colors.white24,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: angle,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                width: 2.5,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? accent : Colors.white70,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          param.name.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: active ? Colors.white70 : Colors.white30,
          ),
        ),
        Text(
          '${param.value}',
          style: TextStyle(
            fontSize: 7.5,
            color: active ? accent.withValues(alpha: 0.9) : Colors.white24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
