import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../theme/app_theme.dart';
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
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;
    final active = effect.isEnabled;

    final bgColor = isDark
        ? (active ? const Color(0xFF222230) : const Color(0xFF181822))
        : (active
            ? Color.lerp(effect.accentColor, Colors.white, 0.84)!
            : const Color(0xFFF1F5F9));

    final borderColor = active
        ? effect.accentColor
        : (isSelected ? const Color(0xFFFF9800) : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)));

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
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: active ? 1.6 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: effect.accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
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
                    color: isDark ? Colors.black45 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark ? Colors.white54 : colors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? effect.accentColor : (isDark ? Colors.black87 : const Color(0xFFCBD5E1)),
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
                color: active
                    ? (isDark ? Colors.white : colors.textPrimary)
                    : (isDark ? Colors.white38 : colors.textMuted),
                letterSpacing: 0.6,
              ),
            ),
            Text(
              active ? 'ON' : 'BYPASS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: active
                    ? (isDark ? effect.accentColor : Color.lerp(effect.accentColor, Colors.black, 0.2)!)
                    : (isDark ? Colors.white24 : colors.textMuted),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.drag_indicator,
              size: 14,
              color: isDark ? Colors.white38 : colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
