import 'package:flutter/material.dart';
import '../../domain/gt1b_assigns.dart';
import '../../services/patch_service.dart';

/// Tab for CTL1 Footswitch, Expression Pedal (EXP), and Toe Switch (EXP SW).
class AssignCtlTab extends StatelessWidget {
  final PatchService patchService;

  const AssignCtlTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final ctl = patchService.ctlExpSetting;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            title: 'CTL1 FOOTSWITCH',
            icon: Icons.touch_app,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'FUNCTION',
                    value: ctl.ctl1Func.clamp(0, Gt1bAssigns.ctl1FuncNames.length - 1),
                    items: Gt1bAssigns.ctl1FuncNames,
                    onChanged: (val) => patchService.updateCtlExp(ctl.copyWith(ctl1Func: val)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'MODE',
                    value: ctl.ctl1Mode.clamp(0, Gt1bAssigns.sourceModeNames.length - 1),
                    items: Gt1bAssigns.sourceModeNames,
                    onChanged: (val) => patchService.updateCtlExp(ctl.copyWith(ctl1Mode: val)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: 'EXP PEDAL (EXPRESSION)',
            icon: Icons.linear_scale,
            child: Column(
              children: [
                _buildDropdown(
                  label: 'FUNCTION',
                  value: ctl.expFunc.clamp(0, Gt1bAssigns.expFuncNames.length - 1),
                  items: Gt1bAssigns.expFuncNames,
                  onChanged: (val) => patchService.updateCtlExp(ctl.copyWith(expFunc: val)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSlider(
                        label: 'MIN',
                        value: ctl.expMin,
                        onChanged: (v) => patchService.updateCtlExp(ctl.copyWith(expMin: v)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSlider(
                        label: 'MAX',
                        value: ctl.expMax,
                        onChanged: (v) => patchService.updateCtlExp(ctl.copyWith(expMax: v)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: 'EXP TOE SWITCH (EXP SW)',
            icon: Icons.power_settings_new,
            child: _buildDropdown(
              label: 'FUNCTION',
              value: ctl.expSwFunc.clamp(0, Gt1bAssigns.expSwFuncNames.length - 1),
              items: Gt1bAssigns.expSwFuncNames,
              onChanged: (val) => patchService.updateCtlExp(ctl.copyWith(expSwFunc: val)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF00ADB5)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
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
