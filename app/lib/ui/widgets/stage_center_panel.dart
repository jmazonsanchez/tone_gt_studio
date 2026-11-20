import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../../models/effect_parameter.dart';
import '../../services/patch_service.dart';
import '../layout/responsive_breakpoints.dart';
import '../theme/app_theme.dart';
import 'assign_editor_modal.dart';
import 'master_workbench_view.dart';
import 'memory_edit_chain_bar.dart';
import 'mini_pedal_card.dart';
import 'param_controls.dart';
import 'parameter_knob.dart';
import 'quick_preset_bar.dart';

/// Center stage workstation panel with Live Preset bar, Signal Chain router,
/// and the Active Boutique Workbench (Option A: compact pedal + centered direct controls).
class StageCenterPanel extends StatefulWidget {
  final PatchService patchService;
  final List<EffectBlock> effects;
  final Function(EffectBlock) onToggleEffect;
  final Function(int fromIndex, int toIndex) onMoveEffect;
  final StageBreakpoint breakpoint;

  const StageCenterPanel({
    super.key,
    required this.patchService,
    required this.effects,
    required this.onToggleEffect,
    required this.onMoveEffect,
    required this.breakpoint,
  });

  @override
  State<StageCenterPanel> createState() => _StageCenterPanelState();
}

class _StageCenterPanelState extends State<StageCenterPanel> {
  int _selectedEffectIndex = 0;

  @override
  void initState() {
    super.initState();
    final firstActive = widget.effects.indexWhere((e) => e.isEnabled);
    if (firstActive >= 0) _selectedEffectIndex = firstActive;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final count = widget.effects.length;
    final isMaster = _selectedEffectIndex == 999;
    final safeIndex = count > 0 ? _selectedEffectIndex.clamp(0, count - 1) : 0;
    final selectedBlock = count > 0 ? widget.effects[safeIndex] : null;

    final liveEffect = selectedBlock != null
        ? (widget.patchService.currentPatch.effects
                .where((e) => e.category == selectedBlock.category)
                .firstOrNull ??
            selectedBlock)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuickPresetBar(patchService: widget.patchService),
          const SizedBox(height: 8),
          MemoryEditChainBar(
            effects: widget.effects,
            selectedIndex: _selectedEffectIndex,
            onSelectIndex: (idx) => setState(() => _selectedEffectIndex = idx),
            onToggle: widget.onToggleEffect,
            onMoveEffect: widget.onMoveEffect,
            onOpenMaster: () => setState(() => _selectedEffectIndex = 999),
            onOpenConfig: () => AssignEditorModal.show(context, widget.patchService),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isMaster
                ? MasterWorkbenchView(
                    patchService: widget.patchService,
                    onClose: () => setState(() => _selectedEffectIndex = safeIndex),
                  )
                : (liveEffect != null
                    ? _buildActiveWorkbench(context, colors, liveEffect, safeIndex, count)
                    : const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkbench(BuildContext ctx, AppColorScheme colors, EffectBlock effect, int idx, int total) {
    final active = effect.isEnabled;
    final accent = effect.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWorkbenchHeader(colors, effect, idx, total, active, accent),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  child: Center(
                    child: MiniPedalCard(effect: effect, onToggle: () => widget.onToggleEffect(effect)),
                  ),
                ),
                Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: colors.borderSubtle),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: _buildParameterConsole(colors, effect, accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbenchHeader(AppColorScheme colors, EffectBlock effect, int idx, int total, bool active, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(effect.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: 0.8)),
          const SizedBox(width: 6),
          Text('•  ${effect.subtitle.toUpperCase()}', style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: colors.isDark ? Colors.black26 : Colors.white70, borderRadius: BorderRadius.circular(5)),
            child: Text('SLOT ${idx + 1}/$total', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textSecondary)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: idx > 0 ? () => setState(() => _selectedEffectIndex = idx - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: idx < total - 1 ? () => setState(() => _selectedEffectIndex = idx + 1) : null,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => widget.onToggleEffect(effect),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active ? accent.withValues(alpha: 0.18) : colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: active ? accent : colors.borderSubtle, width: 1.2),
              ),
              child: Text(
                active ? 'ENCENDIDO' : 'BYPASS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: active ? accent : colors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterConsole(AppColorScheme colors, EffectBlock effect, Color accent) {
    final typeParam = effect.parameters.cast<EffectParameter?>().firstWhere(
          (p) => p != null && p.isEnum && (p.name.toLowerCase().contains('type') || p.name.toLowerCase().contains('mode')),
          orElse: () => null,
        );
    final otherParams = effect.parameters.where((p) => p != typeParam).toList();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (typeParam != null) ...[
            _buildTypeDropdown(colors, typeParam, accent),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: otherParams.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text('Sin parámetros adicionales para este bloque.', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Wrap(
                                spacing: 18,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                runAlignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: otherParams.map((p) {
                                  if (p.isToggle) {
                                    return ToggleParamCard(param: p, accentColor: accent, onChanged: (v) => widget.patchService.updateParameter(p, v));
                                  }
                                  if (p.isEnum) {
                                    return EnumParamDropdown(param: p, accentColor: accent, onChanged: (v) => widget.patchService.updateParameter(p, v));
                                  }
                                  return ParameterKnob(parameter: p, accentColor: accent, onChanged: (v) => widget.patchService.updateParameter(p, v));
                                }).toList(),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(AppColorScheme colors, EffectParameter typeParam, Color accent) {
    final options = typeParam.options ?? const <String>[];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text('TIPO / MODELO:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: typeParam.value.clamp(0, options.isNotEmpty ? options.length - 1 : 0),
                    isDense: true,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colors.textPrimary),
                    dropdownColor: colors.surface,
                    items: options.asMap().entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value.toUpperCase()))).toList(),
                    onChanged: (v) => v != null ? widget.patchService.updateParameter(typeParam, v) : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
