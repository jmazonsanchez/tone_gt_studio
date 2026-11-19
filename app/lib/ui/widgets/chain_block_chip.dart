import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import 'effect_detail_modal.dart';

/// Interactive draggable stompbox chip for the Memory Edit signal chain line.
class ChainBlockChip extends StatelessWidget {
  final EffectBlock effect;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const ChainBlockChip({
    super.key,
    required this.effect,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = effect.isEnabled;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap ?? () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => EffectDetailModal(effect: effect),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 82,
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF222230) : const Color(0xFF181822),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? effect.accentColor
                : (isSelected ? const Color(0xFFFF9800) : Colors.white12),
            width: active ? 1.6 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: effect.accentColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 8, color: Colors.white54, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? effect.accentColor : Colors.black87,
                    boxShadow: active ? [BoxShadow(color: effect.accentColor, blurRadius: 4)] : null,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              effect.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : Colors.white38,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              active ? 'ON' : 'BYPASS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: active ? effect.accentColor : Colors.white24,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.drag_indicator,
              size: 14,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}
