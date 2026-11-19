import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/effect_block.dart';
import '../../models/effect_parameter.dart';
import '../../services/patch_service.dart';
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
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          _buildHeader(context, patchService, liveEffect, active, color),

          const SizedBox(height: 12),

          // 2. Algorithm / Type Selector (if block has a type/mode enum)
          if (typeParam != null) ...[
            _buildTypeSelector(context, patchService, typeParam, color),
            const SizedBox(height: 14),
          ],

          // 3. Parameters Knobs / Sliders Grid
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: otherParams.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No hay parámetros configurables para este bloque.',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
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
    PatchService patchService,
    EffectBlock currentEffect,
    bool active,
    Color color,
  ) {
    return Row(
      children: [
        // Block Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? color.withValues(alpha: 0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: active ? color : Colors.white24,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      active ? 'ACTIVO' : 'BYPASS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: active ? color : Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                currentEffect.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
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
          icon: const Icon(Icons.close, color: Colors.white60, size: 20),
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(
    BuildContext context,
    PatchService patchService,
    EffectParameter typeParam,
    Color color,
  ) {
    final options = typeParam.options ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(Icons.category, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '${typeParam.name.toUpperCase()}:',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white54,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: typeParam.value.clamp(0, options.length - 1),
                dropdownColor: const Color(0xFF222230),
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
