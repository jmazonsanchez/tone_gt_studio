import 'package:flutter/material.dart';
import '../layout/responsive_breakpoints.dart';
import '../theme/app_theme.dart';

class StageRightPanel extends StatelessWidget {
  final bool isWahActive;
  final int wahPosition; // 0 to 100
  final int footVolumeLevel; // 0 to 100 (H10, D6)
  final VoidCallback onToggleWah;
  final ValueChanged<int> onWahPositionChanged;
  final StageBreakpoint breakpoint;

  const StageRightPanel({
    super.key,
    required this.isWahActive,
    required this.wahPosition,
    required this.footVolumeLevel,
    required this.onToggleWah,
    required this.onWahPositionChanged,
    required this.breakpoint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isCompact = breakpoint == StageBreakpoint.compact;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(left: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 11, color: Colors.deepOrangeAccent),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'EXP / VOLUMEN',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Controls (EXP Treadle + Foot Volume Meter side by side)
          Expanded(
            child: Row(
              children: [
                // 1. EXP / WAH Treadle + Toe switch
                Expanded(
                  flex: 3,
                  child: _buildExpTreadle(context, isCompact),
                ),

                const SizedBox(width: 6),

                // 2. Foot Volume Vertical LED Ladder Meter
                Expanded(
                  flex: 2,
                  child: _buildFootVolumeMeter(context, isCompact),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpTreadle(BuildContext context, bool isCompact) {
    final colors = AppTheme.of(context);
    const accent = Colors.deepOrangeAccent;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWahActive ? accent.withValues(alpha: 0.6) : colors.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          // Toe Switch (WAH ON/OFF)
          InkWell(
            onTap: onToggleWah,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isWahActive ? accent.withValues(alpha: 0.2) : colors.cardActive,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isWahActive ? accent : colors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWahActive ? accent : Colors.black45,
                      boxShadow: [
                        if (isWahActive)
                          const BoxShadow(color: accent, blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 4),
                    Text(
                      'WAH TOE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isWahActive ? accent : colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Treadle Visual / Slider
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 18,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  activeTrackColor: isWahActive ? accent : colors.primary,
                  inactiveTrackColor: colors.sliderInactiveTrack,
                  thumbColor: colors.isDark ? Colors.white : colors.primary,
                  overlayColor: (isWahActive ? accent : colors.primary).withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: wahPosition.clamp(0, 100).toDouble(),
                  min: 0,
                  max: 100,
                  onChanged: (val) => onWahPositionChanged(val.toInt()),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Position text
          Text(
            'EXP $wahPosition%',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootVolumeMeter(BuildContext context, bool isCompact) {
    final colors = AppTheme.of(context);
    final level = footVolumeLevel.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          // Label
          Text(
            isCompact ? 'VOL' : 'FOOT VOL',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: colors.textMuted,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          // Multi-segment vertical LED ladder (10 segments)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (idx) {
                // segment index from top (9) to bottom (0)
                final segmentThreshold = (9 - idx) * 10;
                final isLit = level >= segmentThreshold;

                Color segmentColor;
                if (idx < 2) {
                  segmentColor = Colors.redAccent;
                } else if (idx < 5) {
                  segmentColor = Colors.amber;
                } else {
                  segmentColor = colors.primary;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: double.infinity,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isLit ? segmentColor : colors.sliderInactiveTrack,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      if (isLit)
                        BoxShadow(
                          color: segmentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$level%',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
