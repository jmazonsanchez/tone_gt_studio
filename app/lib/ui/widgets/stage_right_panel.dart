import 'package:flutter/material.dart';
import '../layout/responsive_breakpoints.dart';

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
    final isCompact = breakpoint == StageBreakpoint.compact;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        border: Border(left: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (!isCompact)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 11, color: Colors.deepOrangeAccent),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'EXP / VOLUMEN',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white54,
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
    const accent = Colors.deepOrangeAccent;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF181822),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWahActive ? accent.withValues(alpha: 0.6) : Colors.white10,
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
                color: isWahActive ? accent.withValues(alpha: 0.2) : const Color(0xFF22222E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isWahActive ? accent : Colors.white12,
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
                        color: isWahActive ? accent : Colors.white38,
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
                  activeTrackColor: isWahActive ? accent : const Color(0xFF00ADB5),
                  inactiveTrackColor: const Color(0xFF242432),
                  thumbColor: Colors.white,
                  overlayColor: (isWahActive ? accent : const Color(0xFF00ADB5)).withValues(alpha: 0.2),
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
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootVolumeMeter(BuildContext context, bool isCompact) {
    final level = footVolumeLevel.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF181822),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Label
          Text(
            isCompact ? 'VOL' : 'FOOT VOL',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white38,
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
                  segmentColor = const Color(0xFF00ADB5);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: double.infinity,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isLit ? segmentColor : const Color(0xFF22222E),
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
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00ADB5),
            ),
          ),
        ],
      ),
    );
  }
}
