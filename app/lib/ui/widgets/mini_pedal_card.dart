import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../theme/app_theme.dart';
import 'pedal_hardware_widgets.dart';

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
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;
    final active = widget.effect.isEnabled;
    final accent = widget.effect.accentColor;

    final gradientColors = isDark
        ? (active
            ? [
                Color.lerp(accent, Colors.black, 0.45)!,
                Color.lerp(accent, Colors.black, 0.75)!,
                const Color(0xFF16161B),
              ]
            : [
                const Color(0xFF262630),
                const Color(0xFF181820),
                const Color(0xFF101014),
              ])
        : (active
            ? [
                Color.lerp(accent, Colors.white, 0.58)!,
                Color.lerp(accent, Colors.white, 0.82)!,
                Colors.white,
              ]
            : [
                Colors.white,
                const Color(0xFFF8FAFC),
                const Color(0xFFEEF2F6),
              ]);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          if (active)
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.25 : 0.35),
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
              colors: gradientColors,
            ),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: isDark ? 0.8 : 0.95)
                  : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              width: active ? 1.8 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              // Corner Screw Rivets
              const PedalCornerScrew(top: 6, left: 6),
              const PedalCornerScrew(top: 6, right: 6),
              const PedalCornerScrew(bottom: 6, left: 6),
              const PedalCornerScrew(bottom: 6, right: 6),

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
                          PedalJewelLed(active: active, accent: accent),
                          const SizedBox(height: 6),
                          Text(
                            widget.effect.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: active
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
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
                              color: active
                                  ? (isDark ? accent.withValues(alpha: 0.9) : Color.lerp(accent, Colors.black, 0.25)!)
                                  : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
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
                      child: PedalMiniKnobs(
                        params: widget.effect.parameters,
                        active: active,
                        accent: accent,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Deck: 3D Metallic Stompswitch & Status
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _handleStompTap,
                          child: ScaleTransition(
                            scale: _switchAnim,
                            child: PedalChromeFootswitch(active: active, accent: accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          active ? 'ACTIVE' : 'BYPASS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: active
                                ? (isDark ? accent : Color.lerp(accent, Colors.black, 0.15)!)
                                : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
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
}
