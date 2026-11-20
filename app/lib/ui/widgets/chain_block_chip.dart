import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../theme/app_theme.dart';
import 'effect_detail_modal.dart';

/// Minimalist draggable stompbox chip for the Memory Edit signal chain line.
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
        ? (isSelected
            ? (active ? const Color(0xFF262638) : const Color(0xFF1E1E2C))
            : (active ? const Color(0xFF1F1F2B) : const Color(0xFF14141E)))
        : (isSelected
            ? (active ? Color.lerp(effect.accentColor, Colors.white, 0.78)! : Colors.white)
            : (active ? Color.lerp(effect.accentColor, Colors.white, 0.88)! : const Color(0xFFF8FAFC)));

    final borderColor = isSelected
        ? effect.accentColor
        : (active
            ? effect.accentColor.withValues(alpha: isDark ? 0.65 : 0.75)
            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)));

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap ??
          () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => EffectDetailModal(effect: effect),
            );
          },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 78,
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.6 : (active ? 1.2 : 1.0),
          ),
          boxShadow: [
            if (active || isSelected)
              BoxShadow(
                color: effect.accentColor.withValues(alpha: isSelected ? (isDark ? 0.35 : 0.22) : (isDark ? 0.20 : 0.12)),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 1.5),
              ),
            if (!isDark && !active && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark ? Colors.white54 : colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? effect.accentColor : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    boxShadow: active
                        ? [BoxShadow(color: effect.accentColor.withValues(alpha: 0.8), blurRadius: 4)]
                        : null,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  effect.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? (isDark ? Colors.white : colors.textPrimary)
                        : (isDark ? Colors.white38 : colors.textMuted),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  active ? 'ON' : 'BYPASS',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? effect.accentColor
                        : (isDark ? Colors.white24 : colors.textMuted),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.drag_indicator,
              size: 12,
              color: isDark ? Colors.white24 : colors.textMuted.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
