import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../layout/responsive_breakpoints.dart';
import '../theme/app_theme.dart';

/// Dedicated Master Configuration Panel for Boss GT-1B.
/// Replaces the physical buttons section to provide direct live access to:
/// Patch Level, Master BPM, Master Key, and Master 4-Band Parametric EQ.
class StageLeftPanel extends StatelessWidget {
  final PatchService patchService;
  final StageBreakpoint breakpoint;

  static const List<String> musicalKeys = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'
  ];

  static const List<String> midFreqLabels = [
    '100 Hz', '125 Hz', '160 Hz', '200 Hz', '250 Hz', '315 Hz', '400 Hz', '500 Hz',
    '630 Hz', '800 Hz', '1.0 kHz', '1.25 kHz', '1.6 kHz', '2.0 kHz', '2.5 kHz', '3.15 kHz',
    '4.0 kHz', '5.0 kHz', '6.3 kHz', '8.0 kHz', '10.0 kHz'
  ];

  static const List<String> midQLabels = ['0.5', '1', '2', '4', '8', '16'];

  const StageLeftPanel({
    super.key,
    required this.patchService,
    required this.breakpoint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isCompact = breakpoint == StageBreakpoint.compact;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSliderTile(
                    colors: colors,
                    label: 'PATCH LEVEL',
                    value: patchService.patchLevel,
                    min: 0,
                    max: 100,
                    displayValue: '${patchService.patchLevel}',
                    onChanged: (val) => patchService.updateMasterParameter('patch_level', val),
                  ),
                  const SizedBox(height: 8),
                  _buildTempoAndKeyRow(colors),
                  const SizedBox(height: 8),
                  Divider(color: colors.borderSubtle, height: 12),
                  const SizedBox(height: 4),
                  _buildMasterEqSection(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF9800),
            boxShadow: [BoxShadow(color: Color(0xFFFF9800), blurRadius: 4, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'CONFIGURACIÓN MASTER',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Color(0xFFFF9800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempoAndKeyRow(AppColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: _buildSliderTile(
            colors: colors,
            label: 'BPM',
            value: patchService.masterBpm,
            min: 40,
            max: 250,
            displayValue: '${patchService.masterBpm}',
            onChanged: (val) => patchService.updateMasterParameter('master_bpm', val),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildDropdownCard(
            colors: colors,
            label: 'KEY',
            valueIndex: patchService.masterKey.clamp(0, musicalKeys.length - 1),
            items: musicalKeys,
            onChanged: (val) => patchService.updateMasterParameter('master_key', val),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterEqSection(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MASTER 4-BAND EQ',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: colors.textMuted),
        ),
        const SizedBox(height: 6),
        _buildSliderTile(
          colors: colors,
          label: 'LOW GAIN',
          value: patchService.masterEqLow,
          min: 0,
          max: 40,
          displayValue: '${patchService.masterEqLow - 20} dB',
          onChanged: (val) => patchService.updateMasterParameter('master_eq_low', val),
        ),
        const SizedBox(height: 6),
        _buildSliderTile(
          colors: colors,
          label: 'MID GAIN',
          value: patchService.masterEqMidGain,
          min: 0,
          max: 40,
          displayValue: '${patchService.masterEqMidGain - 20} dB',
          onChanged: (val) => patchService.updateMasterParameter('master_eq_mid_gain', val),
        ),
        const SizedBox(height: 6),
        _buildMidFreqAndQRow(colors),
        const SizedBox(height: 6),
        _buildSliderTile(
          colors: colors,
          label: 'HIGH GAIN',
          value: patchService.masterEqHigh,
          min: 0,
          max: 40,
          displayValue: '${patchService.masterEqHigh - 20} dB',
          onChanged: (val) => patchService.updateMasterParameter('master_eq_high', val),
        ),
      ],
    );
  }

  Widget _buildMidFreqAndQRow(AppColorScheme colors) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildDropdownCard(
            colors: colors,
            label: 'MID FREQ',
            valueIndex: patchService.masterEqMidFreq.clamp(0, midFreqLabels.length - 1),
            items: midFreqLabels,
            onChanged: (val) => patchService.updateMasterParameter('master_eq_mid_freq', val),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _buildDropdownCard(
            colors: colors,
            label: 'MID Q',
            valueIndex: patchService.masterEqMidQ.clamp(0, midQLabels.length - 1),
            items: midQLabels,
            onChanged: (val) => patchService.updateMasterParameter('master_eq_mid_q', val),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCard({
    required AppColorScheme colors,
    required String label,
    required int valueIndex,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.textMuted)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: valueIndex,
              isDense: true,
              isExpanded: true,
              dropdownColor: colors.surfaceElevated,
              style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 11),
              items: List.generate(items.length, (idx) => DropdownMenuItem(value: idx, child: Text(items[idx]))),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required AppColorScheme colors,
    required String label,
    required int value,
    required int min,
    required int max,
    required String displayValue,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.textMuted),
                ),
              ),
              const SizedBox(width: 4),
              Text(displayValue, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: Color(0xFFFF9800),
              inactiveTrackColor: Colors.white10,
              thumbColor: Color(0xFFFF9800),
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
