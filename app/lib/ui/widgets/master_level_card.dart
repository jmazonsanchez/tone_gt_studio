import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Touch-friendly Output / Patch Level Fader Card for Master Workbench.
/// Features a tall vertical fader and generous +/-5 step buttons.
class MasterLevelCard extends StatelessWidget {
  final PatchService patchService;
  final AppColorScheme colors;

  const MasterLevelCard({
    super.key,
    required this.patchService,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFF9800);
    final level = patchService.patchLevel;

    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_up_rounded, size: 14, color: amber),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'PATCH LEVEL',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: amber.withValues(alpha: 0.4)),
            ),
            child: Text(
              '$level',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: amber),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      activeTrackColor: amber,
                      thumbColor: amber,
                      inactiveTrackColor: colors.borderSubtle,
                    ),
                    child: Slider(
                      value: level.toDouble(),
                      min: 0,
                      max: 100,
                      onChanged: (v) => patchService.updateMasterParameter('patch_level', v.round()),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepBtn(Icons.add, () => patchService.updateMasterParameter('patch_level', (level + 5).clamp(0, 100))),
                    _buildStepBtn(Icons.remove, () => patchService.updateMasterParameter('patch_level', (level - 5).clamp(0, 100))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }
}
