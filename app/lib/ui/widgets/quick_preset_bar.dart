import 'package:flutter/material.dart';
import '../../models/patch.dart';
import '../../models/quick_preset.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';
import 'quick_preset_editor_modal.dart';

/// Live Quick Preset Access Bar (Accesos Directos en Vivo).
/// Placed right above the Signal Chain section for rapid 1-tap preset switching on stage.
class QuickPresetBar extends StatelessWidget {
  final PatchService patchService;

  const QuickPresetBar({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final quickPresets = patchService.quickPresets;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [Color(0xFF14141F), Color(0xFF1A1A28)]
              : const [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStageBadge(colors, quickPresets.length),
          const SizedBox(width: 8),
          Expanded(
            child: quickPresets.isEmpty
                ? _buildEmptyState(context, colors)
                : _buildPresetList(context, quickPresets, colors),
          ),
          const SizedBox(width: 6),
          _buildAddButton(context, colors),
        ],
      ),
    );
  }

  Widget _buildStageBadge(AppColorScheme colors, int count) {
    const liveColor = Color(0xFFFF334B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF101018) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: liveColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: liveColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: liveColor.withValues(alpha: 0.65), blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'EN VIVO',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: colors.isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
              decoration: BoxDecoration(
                color: liveColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: liveColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorScheme colors) {
    return InkWell(
      onTap: () => QuickPresetEditorModal.show(context, patchService),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: colors.isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 13, color: colors.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Sin accesos directos • Toca "+" para agregar presets a tu setlist en vivo',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, letterSpacing: 0.2, color: colors.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetList(BuildContext context, List<QuickPreset> quickPresets, AppColorScheme colors) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: quickPresets.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final qp = quickPresets[index];
        final isSelected = patchService.currentPatchIndex == qp.patchIndex;
        final patch = _resolvePatch(qp.patchIndex);
        return _buildShortcutChip(context, qp, patch, isSelected, Color(qp.colorValue), colors);
      },
    );
  }

  Patch? _resolvePatch(int patchIndex) {
    if (patchService.patches.isNotEmpty && patchIndex < patchService.patches.length) {
      return patchService.patches[patchIndex];
    }
    return null;
  }

  Widget _buildShortcutChip(
    BuildContext context,
    QuickPreset qp,
    Patch? patch,
    bool isSelected,
    Color tagColor,
    AppColorScheme colors,
  ) {
    final patchNumber = patch?.displayNumber ?? 'U${(qp.patchIndex + 1).toString().padLeft(2, '0')}';
    final label = qp.customLabel.isNotEmpty ? qp.customLabel : (patch?.name ?? 'PRESET ${qp.patchIndex}');
    final bgColor = isSelected
        ? (colors.isDark ? Color.lerp(tagColor, const Color(0xFF1E1E2C), 0.85)! : Color.lerp(tagColor, Colors.white, 0.86)!)
        : (colors.isDark ? const Color(0xFF181824) : const Color(0xFFF1F5F9));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => patchService.selectPatch(qp.patchIndex),
        onLongPress: () => QuickPresetEditorModal.show(context, patchService, existing: qp),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? tagColor : tagColor.withValues(alpha: colors.isDark ? 0.3 : 0.4),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: tagColor.withValues(alpha: colors.isDark ? 0.35 : 0.22), blurRadius: 8, offset: const Offset(0, 1.5))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: isSelected ? 0.95 : 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  patchNumber,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: isSelected ? Colors.black : tagColor),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => QuickPresetEditorModal.show(context, patchService, existing: qp),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.tune_rounded, size: 12, color: isSelected ? tagColor : colors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppColorScheme colors) {
    const accent = Color(0xFF00ADB5);
    return InkWell(
      key: const Key('add-quick-preset-btn'),
      onTap: () => QuickPresetEditorModal.show(context, patchService),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF162330) : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: colors.isDark ? 0.45 : 0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: accent),
            SizedBox(width: 4),
            Text(
              'AGREGAR',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: accent, letterSpacing: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
