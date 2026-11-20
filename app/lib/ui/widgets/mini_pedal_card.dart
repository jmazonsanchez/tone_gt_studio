import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../theme/app_theme.dart';
import 'pedal_hardware_widgets.dart';

/// Boutique Stompbox Mini-Pedal Widget.
/// Faithfully replicates the physical look, knurled knobs, jewel LED, and chrome footswitch of a compact boutique pedal.
class MiniPedalCard extends StatefulWidget {
  final EffectBlock effect;
  final VoidCallback onToggle;
  final VoidCallback? onOpenDetail;

  const MiniPedalCard({
    super.key,
    required this.effect,
    required this.onToggle,
    this.onOpenDetail,
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
      duration: const Duration(milliseconds: 90),
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
    _switchAnim.reverse().then((_) => _switchAnim.forward());
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
            : const [Color(0xFF24242E), Color(0xFF181820), Color(0xFF101014)])
        : (active
            ? [
                Color.lerp(accent, Colors.white, 0.58)!,
                Color.lerp(accent, Colors.white, 0.82)!,
                Colors.white,
              ]
            : const [Colors.white, Color(0xFFF8FAFC), Color(0xFFEEF2F6)]);

    return Center(
      child: Container(
        width: 125,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            if (active)
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.3 : 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: active
                    ? accent.withValues(alpha: isDark ? 0.85 : 0.95)
                    : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                width: active ? 1.6 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Corner Screws
                const PedalCornerScrew(top: 5, left: 5),
                const PedalCornerScrew(top: 5, right: 5),
                const PedalCornerScrew(bottom: 5, left: 5),
                const PedalCornerScrew(bottom: 5, right: 5),

                // Main Face
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 105,
                      height: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Deck
                      GestureDetector(
                        onTap: widget.onOpenDetail,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            PedalJewelLed(active: active, accent: accent),
                            const SizedBox(height: 4),
                            Text(
                              widget.effect.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
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
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: active
                                    ? (isDark ? accent.withValues(alpha: 0.95) : Color.lerp(accent, Colors.black, 0.25)!)
                                    : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Middle Knobs Deck
                      GestureDetector(
                        onTap: widget.onOpenDetail,
                        behavior: HitTestBehavior.opaque,
                        child: PedalMiniKnobs(
                          params: widget.effect.parameters,
                          active: active,
                          accent: accent,
                        ),
                      ),

                      // Bottom Stomp Deck
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _handleStompTap,
                            child: ScaleTransition(
                              scale: _switchAnim,
                              child: PedalChromeFootswitch(active: active, accent: accent),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            active ? 'ACTIVE' : 'BYPASS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: active
                                  ? (isDark ? accent : Color.lerp(accent, Colors.black, 0.2)!)
                                  : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
