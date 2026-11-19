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
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // 1. Live Indicator Badge
          _buildStageBadge(colors),
          const SizedBox(width: 8),

          // 2. Horizontal Scrollable List of Quick Presets
          Expanded(
            child: quickPresets.isEmpty
                ? _buildEmptyState(colors)
                : _buildPresetList(context, quickPresets, colors),
          ),
          const SizedBox(width: 6),

          // 3. Add Quick Preset Button
          _buildAddButton(context, colors),
        ],
      ),
    );
  }

  Widget _buildStageBadge(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, size: 14, color: Color(0xFF00ADB5)),
          const SizedBox(width: 4),
          Text(
            'EN VIVO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colors) {
    return Center(
      child: Text(
        'Toca "+" para agregar accesos directos para tu show en vivo',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: colors.textMuted,
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
        final tagColor = Color(qp.colorValue);

        return _buildShortcutChip(context, qp, patch, isSelected, tagColor, colors);
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => patchService.selectPatch(qp.patchIndex),
        onLongPress: () => QuickPresetEditorModal.show(context, patchService, existing: qp),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? tagColor.withValues(alpha: 0.22) : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? tagColor : colors.borderSubtle,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: tagColor.withValues(alpha: 0.35), blurRadius: 6, spreadRadius: 0.5)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),

              // Number Badge
              Text(
                patchNumber,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? tagColor : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),

              // Custom Label
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),

              // Edit Icon Button
              InkWell(
                onTap: () => QuickPresetEditorModal.show(context, patchService, existing: qp),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: isSelected ? tagColor : colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppColorScheme colors) {
    return InkWell(
      key: const Key('add-quick-preset-btn'),
      onTap: () => QuickPresetEditorModal.show(context, patchService),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: colors.primary),
            const SizedBox(width: 4),
            Text(
              'AGREGAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
