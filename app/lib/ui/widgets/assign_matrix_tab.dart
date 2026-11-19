import 'package:flutter/material.dart';
import '../../domain/gt1b_assigns.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Tab for Boss GT-1B Assign Matrices A1 to A6.
class AssignMatrixTab extends StatefulWidget {
  final PatchService patchService;

  const AssignMatrixTab({super.key, required this.patchService});

  @override
  State<AssignMatrixTab> createState() => _AssignMatrixTabState();
}

class _AssignMatrixTabState extends State<AssignMatrixTab> {
  int _selectedAssignIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final assigns = widget.patchService.assigns;
    if (_selectedAssignIndex >= assigns.length) {
      _selectedAssignIndex = 0;
    }
    final currentAssign = assigns[_selectedAssignIndex];

    return Row(
      children: [
        // Assign A1..A6 Selector Sidebar
        SizedBox(
          width: 140,
          child: ListView.builder(
            itemCount: assigns.length,
            itemBuilder: (context, idx) {
              final a = assigns[idx];
              final isSel = _selectedAssignIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedAssignIndex = idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? (colors.isDark ? const Color(0xFF1E2838) : colors.cardActive) : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? colors.primary : colors.borderSubtle,
                        width: isSel ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'ASSIGN ${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? colors.primary : colors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: a.isEnabled ? colors.primary : colors.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        VerticalDivider(width: 24, color: colors.borderSubtle),
        // Active Assign Detail Form
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ASIGNACIÓN A${_selectedAssignIndex + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.primary),
                    ),
                    Switch(
                      value: currentAssign.isEnabled,
                      activeColor: colors.primary,
                      onChanged: (val) {
                        widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(isEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDropdown(
                  colors,
                  'TARGET PARAMETER',
                  currentAssign.target.clamp(0, Gt1bAssigns.targetNames.length - 1),
                  Gt1bAssigns.targetNames,
                  (val) => widget.patchService.updateAssign(
                    _selectedAssignIndex,
                    currentAssign.copyWith(target: val),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSlider(
                        colors,
                        'TARGET MIN',
                        currentAssign.targetMin,
                        (v) => widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(targetMin: v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSlider(
                        colors,
                        'TARGET MAX',
                        currentAssign.targetMax,
                        (v) => widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(targetMax: v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        colors,
                        'SOURCE',
                        currentAssign.source.clamp(0, Gt1bAssigns.assignSourceNames.length - 1),
                        Gt1bAssigns.assignSourceNames,
                        (val) => widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(source: val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDropdown(
                        colors,
                        'SOURCE MODE',
                        currentAssign.sourceMode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1),
                        Gt1bAssigns.sourceModeNames,
                        (val) => widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(sourceMode: val),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
