import 'package:flutter/material.dart';
import '../../models/effect_parameter.dart';
import '../theme/app_theme.dart';

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
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;
    final isChecked = param.value > 0;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isChecked ? accentColor : (isDark ? Colors.white10 : const Color(0xFFCBD5E1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            param.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
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
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;
    final options = param.options ?? [];
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            param.name.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: param.value.clamp(0, options.length - 1),
              dropdownColor: colors.surfaceElevated,
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
