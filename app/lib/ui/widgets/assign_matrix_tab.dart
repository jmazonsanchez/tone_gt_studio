import 'package:flutter/material.dart';
import '../../domain/gt1b_assigns.dart';
import '../../services/patch_service.dart';

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
                      color: isSel ? const Color(0xFF1E2838) : const Color(0xFF181824),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? const Color(0xFF00ADB5) : Colors.white10,
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
                              color: isSel ? const Color(0xFF00ADB5) : Colors.white70,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: a.isEnabled ? const Color(0xFF00ADB5) : Colors.white24,
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
        const VerticalDivider(width: 24, color: Colors.white12),
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
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF00ADB5)),
                    ),
                    Switch(
                      value: currentAssign.isEnabled,
                      activeColor: const Color(0xFF00ADB5),
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
                  label: 'TARGET PARAMETER',
                  value: currentAssign.target.clamp(0, Gt1bAssigns.targetNames.length - 1),
                  items: Gt1bAssigns.targetNames,
                  onChanged: (val) => widget.patchService.updateAssign(
                    _selectedAssignIndex,
                    currentAssign.copyWith(target: val),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSlider(
                        label: 'TARGET MIN',
                        value: currentAssign.targetMin,
                        onChanged: (v) => widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(targetMin: v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSlider(
                        label: 'TARGET MAX',
                        value: currentAssign.targetMax,
                        onChanged: (v) => widget.patchService.updateAssign(
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
                        label: 'SOURCE',
                        value: currentAssign.source.clamp(0, Gt1bAssigns.assignSourceNames.length - 1),
                        items: Gt1bAssigns.assignSourceNames,
                        onChanged: (val) => widget.patchService.updateAssign(
                          _selectedAssignIndex,
                          currentAssign.copyWith(source: val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDropdown(
                        label: 'SOURCE MODE',
                        value: currentAssign.sourceMode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1),
                        items: Gt1bAssigns.sourceModeNames,
                        onChanged: (val) => widget.patchService.updateAssign(
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

  Widget _buildDropdown({
    required String label,
    required int value,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF222230),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Color(0xFF00ADB5), fontSize: 12, fontWeight: FontWeight.bold),
              items: List.generate(items.length, (idx) {
                return DropdownMenuItem(value: idx, child: Text(items[idx]));
              }),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
            Text('$value', style: const TextStyle(fontSize: 10, color: Color(0xFF00ADB5), fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 2,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 8),
            activeTrackColor: Color(0xFF00ADB5),
            inactiveTrackColor: Colors.white10,
            thumbColor: Color(0xFF00ADB5),
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
