import 'package:flutter/material.dart';
import '../../models/effect_parameter.dart';

class ToggleParamCard extends StatelessWidget {
  final EffectParameter param;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const ToggleParamCard({
    super.key,
    required this.param,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = param.value > 0;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isChecked ? accentColor : Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            param.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Switch(
            value: isChecked,
            activeColor: accentColor,
            onChanged: (val) => onChanged(val ? 1 : 0),
          ),
        ],
      ),
    );
  }
}

class EnumParamDropdown extends StatelessWidget {
  final EffectParameter param;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const EnumParamDropdown({
    super.key,
    required this.param,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = param.options ?? [];
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            param.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white54,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: param.value.clamp(0, options.length - 1),
              dropdownColor: const Color(0xFF222230),
              isDense: true,
              isExpanded: true,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              items: List.generate(options.length, (idx) {
                return DropdownMenuItem<int>(
                  value: idx,
                  child: Text(options[idx]),
                );
              }),
              onChanged: (newIdx) {
                if (newIdx != null) {
                  onChanged(newIdx);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
