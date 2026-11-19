import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/effect_block.dart';
import '../../models/effect_parameter.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';
import 'param_controls.dart';
import 'parameter_knob.dart';

/// Generic Deep Parameter Editor Panel for GT-1B effect blocks.
/// Driven directly by the GT-1B parameter catalog.
class EffectEditorPanel extends StatelessWidget {
  final EffectBlock effect;
  final VoidCallback? onClose;

  const EffectEditorPanel({
    super.key,
    required this.effect,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final patchService = context.watch<PatchService>();
    final liveEffect = patchService.currentPatch.effects
        .where((e) => e.category == effect.category)
        .firstOrNull ?? effect;
    final colors = AppTheme.of(context);
    final active = liveEffect.isEnabled;
    final color = liveEffect.accentColor;

    // Find primary type parameter if present (e.g. comp_type, od_type, amp_type, fx_type)
    final typeParam = liveEffect.parameters.cast<EffectParameter?>().firstWhere(
      (p) => p != null && p.isEnum && (p.name.toLowerCase().contains('type') || p.name.toLowerCase().contains('mode')),
      orElse: () => null,
    );

    // Other parameters (knobs, sliders, toggles)
    final otherParams = liveEffect.parameters.where((p) => p != typeParam).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          _buildHeader(context, colors, patchService, liveEffect, active, color),

          const SizedBox(height: 12),

          // 2. Algorithm / Type Selector (if block has a type/mode enum)
          if (typeParam != null) ...[
            _buildTypeSelector(context, colors, patchService, typeParam, color),
            const SizedBox(height: 14),
          ],

          // 3. Parameters Knobs / Sliders Grid
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: otherParams.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No hay parámetros configurables para este bloque.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  : Center(
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: otherParams.map((param) {
                          if (param.isToggle) {
                            return ToggleParamCard(
                              param: param,
                              accentColor: color,
                              onChanged: (newVal) => patchService.updateParameter(param, newVal),
                            );
                          }
                          if (param.isEnum) {
                            return EnumParamDropdown(
                              param: param,
                              accentColor: color,
                              onChanged: (newVal) => patchService.updateParameter(param, newVal),
                            );
                          }
                          return ParameterKnob(
                            parameter: param,
                            accentColor: color,
                            onChanged: (newVal) => patchService.updateParameter(param, newVal),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppColorScheme colors,
    PatchService patchService,
    EffectBlock currentEffect,
    bool active,
    Color color,
  ) {
    final isDark = colors.isDark;
    return Row(
      children: [
        // Block Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.6)),
          ),
          child: Icon(Icons.tune, color: color, size: 20),
        ),

        const SizedBox(width: 12),

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    currentEffect.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? color.withValues(alpha: isDark ? 0.2 : 0.12) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: active ? color : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      active ? 'ACTIVO' : 'BYPASS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: active ? color : colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                currentEffect.subtitle,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),

        // Bypass Switch
        Switch(
          value: active,
          activeColor: color,
          onChanged: (val) => patchService.toggleEffect(currentEffect),
        ),

        const SizedBox(width: 8),

        // Close Button
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close, color: colors.textMuted, size: 20),
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(
    BuildContext context,
    AppColorScheme colors,
    PatchService patchService,
    EffectParameter typeParam,
    Color color,
  ) {
    final options = typeParam.options ?? [];
    final isDark = colors.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Icon(Icons.category, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '${typeParam.name.toUpperCase()}:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: colors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: typeParam.value.clamp(0, options.length - 1),
                dropdownColor: colors.surfaceElevated,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: color),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.6,
                ),
                items: List.generate(options.length, (idx) {
                  return DropdownMenuItem<int>(
                    value: idx,
                    child: Text(options[idx]),
                  );
                }),
                onChanged: (newIdx) {
                  if (newIdx != null) {
                    patchService.updateParameter(typeParam, newIdx);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
