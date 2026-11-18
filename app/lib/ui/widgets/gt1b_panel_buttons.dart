import 'package:flutter/material.dart';
import '../../models/effect_block.dart';

/// Physical GT-1B Front Panel Backlit Black Buttons Row
/// Replicates the illuminated silicone black buttons located directly on the Boss GT-1B front panel.
class Gt1bPanelButtons extends StatelessWidget {
  final List<EffectBlock> effects;
  final Function(EffectBlock) onToggle;

  const Gt1bPanelButtons({
    super.key,
    required this.effects,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Core physical GT-1B front panel buttons
    final panelEffects = effects.where((e) =>
      e.category == EffectCategory.comp ||
      e.category == EffectCategory.odDs ||
      e.category == EffectCategory.preamp ||
      e.category == EffectCategory.eq ||
      e.category == EffectCategory.fx1 ||
      e.category == EffectCategory.fx2 ||
      e.category == EffectCategory.delay ||
      e.category == EffectCategory.reverb ||
      e.category == EffectCategory.pedalFx ||
      e.category == EffectCategory.footVolume ||
      e.category == EffectCategory.noiseSuppressor
    ).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Icon(Icons.radio_button_checked, size: 12, color: Colors.redAccent),
                SizedBox(width: 5),
                Text(
                  'BOTONES FRONTALES GT-1B (RETROILUMINADOS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: panelEffects.map((effect) {
                final active = effect.isEnabled;
                final label = _formatButtonLabel(effect.category);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onToggle(effect),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 58,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2A2A34),
                            Color(0xFF181820),
                            Color(0xFF121216),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? Colors.redAccent : Colors.black87,
                          width: active ? 1.4 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                          if (active)
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: active ? Colors.white : Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Backlit LED Slot
                          Container(
                            width: 22,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: active ? Colors.redAccent : const Color(0xFF252528),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: active
                                  ? [
                                      const BoxShadow(
                                        color: Colors.redAccent,
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatButtonLabel(EffectCategory cat) {
    switch (cat) {
      case EffectCategory.comp:
        return 'COMP';
      case EffectCategory.odDs:
        return 'OD/DS';
      case EffectCategory.preamp:
        return 'PREAMP';
      case EffectCategory.fx1:
        return 'FX1';
      case EffectCategory.fx2:
        return 'FX2';
      case EffectCategory.delay:
        return 'DELAY';
      case EffectCategory.chorus:
        return 'CHORUS';
      case EffectCategory.reverb:
        return 'REV';
      case EffectCategory.pedalFx:
        return 'WAH';
      case EffectCategory.noiseSuppressor:
        return 'NS';
      case EffectCategory.footVolume:
        return 'FV';
      case EffectCategory.eq:
        return 'EQ';
    }
  }
}
