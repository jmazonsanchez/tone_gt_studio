import 'package:flutter/material.dart';
import '../../domain/gt1b_assigns.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Tab for CTL1, EXP1, EXP1 SW, CTL2, CTL3, and EXP2.
class AssignCtlTab extends StatelessWidget {
  final PatchService patchService;

  const AssignCtlTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final ctl = patchService.ctlExpSetting;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            colors: colors,
            title: 'CTL1 FOOTSWITCH',
            icon: Icons.touch_app,
            child: Row(
              children: [
                Expanded(child: _buildDropdown(colors, 'FUNCTION', ctl.ctl1Func.clamp(0, Gt1bAssigns.ctl1FuncNames.length - 1), Gt1bAssigns.ctl1FuncNames, (v) => patchService.updateCtlExp(ctl.copyWith(ctl1Func: v)))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown(colors, 'MODE', ctl.ctl1Mode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1), Gt1bAssigns.sourceModeNames, (v) => patchService.updateCtlExp(ctl.copyWith(ctl1Mode: v)))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildCard(
            colors: colors,
            title: 'EXP1 PEDAL & EXP1 TOE SWITCH',
            icon: Icons.linear_scale,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDropdown(colors, 'EXP1 FUNCTION', ctl.expFunc.clamp(0, Gt1bAssigns.expFuncNames.length - 1), Gt1bAssigns.expFuncNames, (v) => patchService.updateCtlExp(ctl.copyWith(expFunc: v)))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown(colors, 'EXP1 TOE SWITCH (EXP SW)', ctl.expSwFunc.clamp(0, Gt1bAssigns.expSwFuncNames.length - 1), Gt1bAssigns.expSwFuncNames, (v) => patchService.updateCtlExp(ctl.copyWith(expSwFunc: v)))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSlider(colors, 'MIN', ctl.expMin, (v) => patchService.updateCtlExp(ctl.copyWith(expMin: v)))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSlider(colors, 'MAX', ctl.expMax, (v) => patchService.updateCtlExp(ctl.copyWith(expMax: v)))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildCard(
            colors: colors,
            title: 'SUB CTL2 & SUB CTL3 (FOOTSWITCHES)',
            icon: Icons.alt_route,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildDropdown(colors, 'CTL2 FUNCTION', ctl.ctl2Func.clamp(0, Gt1bAssigns.ctl2FuncNames.length - 1), Gt1bAssigns.ctl2FuncNames, (v) => patchService.updateCtlExp(ctl.copyWith(ctl2Func: v))),
                      const SizedBox(height: 8),
                      _buildDropdown(colors, 'CTL2 MODE', ctl.ctl2Mode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1), Gt1bAssigns.sourceModeNames, (v) => patchService.updateCtlExp(ctl.copyWith(ctl2Mode: v))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildDropdown(colors, 'CTL3 FUNCTION', ctl.ctl3Func.clamp(0, Gt1bAssigns.ctl3FuncNames.length - 1), Gt1bAssigns.ctl3FuncNames, (v) => patchService.updateCtlExp(ctl.copyWith(ctl3Func: v))),
                      const SizedBox(height: 8),
                      _buildDropdown(colors, 'CTL3 MODE', ctl.ctl3Mode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1), Gt1bAssigns.sourceModeNames, (v) => patchService.updateCtlExp(ctl.copyWith(ctl3Mode: v))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildCard(
            colors: colors,
            title: 'SUB EXP2 (PEDAL DE EXPRESIÓN 2)',
            icon: Icons.tune,
            child: Column(
              children: [
                _buildDropdown(colors, 'EXP2 FUNCTION', ctl.exp2Func.clamp(0, Gt1bAssigns.exp2FuncNames.length - 1), Gt1bAssigns.exp2FuncNames, (v) => patchService.updateCtlExp(ctl.copyWith(exp2Func: v))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSlider(colors, 'EXP2 MIN', ctl.exp2Min, (v) => patchService.updateCtlExp(ctl.copyWith(exp2Min: v)))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSlider(colors, 'EXP2 MAX', ctl.exp2Max, (v) => patchService.updateCtlExp(ctl.copyWith(exp2Max: v)))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required AppColorScheme colors,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown(AppColorScheme colors, String label, int value, List<String> items, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: colors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: colors.surfaceElevated,
              style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              items: List.generate(items.length, (idx) => DropdownMenuItem(value: idx, child: Text(items[idx]))),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(AppColorScheme colors, String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: colors.textMuted, fontWeight: FontWeight.bold)),
            Text('$value', style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.sliderInactiveTrack,
            thumbColor: colors.primary,
          ),
          child: Slider(
            value: value.toDouble().clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
