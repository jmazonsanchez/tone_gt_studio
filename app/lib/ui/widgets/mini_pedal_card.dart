import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../../models/effect_parameter.dart';

/// Boutique Stompbox Mini-Pedal Widget
/// Faithfully replicates the physical look, knurled knobs, jewel LED, and chrome footswitch of a boutique pedal.
class MiniPedalCard extends StatefulWidget {
  final EffectBlock effect;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetail;

  const MiniPedalCard({
    super.key,
    required this.effect,
    required this.onToggle,
    required this.onOpenDetail,
  });

  @override
  State<MiniPedalCard> createState() => _MiniPedalCardState();
}

class _MiniPedalCardState extends State<MiniPedalCard> with SingleTickerProviderStateMixin {
  late AnimationController _switchAnim;

  @override
  void initState() {
    super.initState();
    _switchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _switchAnim.dispose();
    super.dispose();
  }

  void _handleStompTap() {
    _switchAnim.reverse().then((_) {
      _switchAnim.forward();
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.effect.isEnabled;
    final accent = widget.effect.accentColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
          if (active)
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: active
                  ? [
                      Color.lerp(accent, Colors.black, 0.45)!,
                      Color.lerp(accent, Colors.black, 0.75)!,
                      const Color(0xFF16161B),
                    ]
                  : [
                      const Color(0xFF262630),
                      const Color(0xFF181820),
                      const Color(0xFF101014),
                    ],
            ),
            border: Border.all(
              color: active ? accent.withValues(alpha: 0.8) : Colors.white12,
              width: active ? 1.8 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              // Corner Screw Rivets
              _buildCornerScrew(top: 6, left: 6),
              _buildCornerScrew(top: 6, right: 6),
              _buildCornerScrew(bottom: 6, left: 6),
              _buildCornerScrew(bottom: 6, right: 6),

              // Main Pedal Face Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Deck: Jewel LED & Pedal Brand
                  GestureDetector(
                    onTap: widget.onOpenDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: Column(
                        children: [
                          // Jewel LED
                          _buildJewelLed(active, accent),
                          const SizedBox(height: 6),
                          // Pedal Model Stamped Title
                          Text(
                            widget.effect.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: active ? Colors.white : Colors.white60,
                            ),
                          ),
                          Text(
                            widget.effect.subtitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: active ? accent.withValues(alpha: 0.9) : Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Middle Deck: Mini Knobs
                  GestureDetector(
                    onTap: widget.onOpenDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildMiniKnobs(widget.effect.parameters, active, accent),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Deck: 3D Metallic Stompswitch & Status
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    child: Column(
                      children: [
                        // Chrome Footswitch
                        GestureDetector(
                          onTap: _handleStompTap,
                          child: ScaleTransition(
                            scale: _switchAnim,
                            child: _buildChromeFootswitch(active, accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bypass / Active Indicator
                        Text(
                          active ? 'ACTIVE' : 'BYPASS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: active ? accent : Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerScrew({double? top, double? bottom, double? left, double? right}) {
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

  Widget _buildJewelLed(bool active, Color accent) {
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

  Widget _buildMiniKnobs(List<EffectParameter> params, bool active, Color accent) {
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
            child: _buildSingleMiniKnob(p, active, accent),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleMiniKnob(EffectParameter param, bool active, Color accent) {
    // Calculate angle: 0 to 100 maps to -135 deg to +135 deg
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

  Widget _buildChromeFootswitch(bool active, Color accent) {
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
