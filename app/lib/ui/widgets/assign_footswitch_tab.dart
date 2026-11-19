import 'package:flutter/material.dart';
import '../../domain/gt1b_assigns.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Tab for Footswitches (Down / Up) and System I/O Levels (In Level / Out Level).
class AssignFootswitchTab extends StatelessWidget {
  final PatchService patchService;

  const AssignFootswitchTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final ctl = patchService.ctlExpSetting;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            colors: colors,
            title: 'FOOTSWITCH DOWN',
            icon: Icons.arrow_downward,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    colors,
                    'FUNCTION',
                    ctl.downFunc.clamp(0, Gt1bAssigns.downFuncNames.length - 1),
                    Gt1bAssigns.downFuncNames,
                    (val) => patchService.updateCtlExp(ctl.copyWith(downFunc: val)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    colors,
                    'MODE',
                    ctl.downMode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1),
                    Gt1bAssigns.sourceModeNames,
                    (val) => patchService.updateCtlExp(ctl.copyWith(downMode: val)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            colors: colors,
            title: 'FOOTSWITCH UP',
            icon: Icons.arrow_upward,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    colors,
                    'FUNCTION',
                    ctl.upFunc.clamp(0, Gt1bAssigns.upFuncNames.length - 1),
                    Gt1bAssigns.upFuncNames,
                    (val) => patchService.updateCtlExp(ctl.copyWith(upFunc: val)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    colors,
                    'MODE',
                    ctl.upMode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1),
                    Gt1bAssigns.sourceModeNames,
                    (val) => patchService.updateCtlExp(ctl.copyWith(upMode: val)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            colors: colors,
            title: 'NIVELES GLOBALES DE ENTRADA Y SALIDA (I/O)',
            icon: Icons.volume_up,
            child: Row(
              children: [
                Expanded(
                  child: _buildSlider(
                    colors,
                    'IN LEVEL (ENTRADA)',
                    ctl.inLevel,
                    (v) => patchService.updateCtlExp(ctl.copyWith(inLevel: v)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildSlider(
                    colors,
                    'OUT LEVEL (SALIDA)',
                    ctl.outLevel,
                    (v) => patchService.updateCtlExp(ctl.copyWith(outLevel: v)),
                  ),
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
