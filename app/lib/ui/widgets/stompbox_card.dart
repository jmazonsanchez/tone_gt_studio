import 'package:flutter/material.dart';
import '../../models/effect_block.dart';

class StompboxCard extends StatelessWidget {
  final EffectBlock effect;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetail;

  const StompboxCard({
    super.key,
    required this.effect,
    required this.onToggle,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final active = effect.isEnabled;
    final color = effect.accentColor;

    return GestureDetector(
      onTap: onOpenDetail,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF242430) : const Color(0xFF16161B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color : Colors.white12,
            width: active ? 2.0 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  effect.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.1,
                    color: active ? Colors.white : Colors.white38,
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? color.withOpacity(0.2) : Colors.transparent,
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? color : Colors.black45,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: color,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: active ? Colors.white : Colors.white24,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    effect.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white70 : Colors.white30,
                    ),
                  ),
                ),
                const Icon(Icons.tune, size: 14, color: Colors.white24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
