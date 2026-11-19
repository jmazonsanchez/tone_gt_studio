import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../layout/responsive_breakpoints.dart';

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
    final isCompact = breakpoint == StageBreakpoint.compact;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        border: Border(right: BorderSide(color: Colors.white10, width: 1)),
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
                    label: 'PATCH LEVEL',
                    value: patchService.patchLevel,
                    min: 0,
                    max: 100,
                    displayValue: '${patchService.patchLevel}',
                    onChanged: (val) => patchService.updateMasterParameter('patch_level', val),
                  ),
                  const SizedBox(height: 8),
                  _buildTempoAndKeyRow(),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10, height: 12),
                  const SizedBox(height: 4),
                  _buildMasterEqSection(),
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

  Widget _buildTempoAndKeyRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSliderTile(
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
            label: 'KEY',
            valueIndex: patchService.masterKey.clamp(0, musicalKeys.length - 1),
            items: musicalKeys,
            onChanged: (val) => patchService.updateMasterParameter('master_key', val),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterEqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MASTER 4-BAND EQ',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white54),
        ),
        const SizedBox(height: 6),
        _buildSliderTile(
          label: 'LOW GAIN',
          value: patchService.masterEqLow,
          min: 0,
          max: 40,
          displayValue: '${patchService.masterEqLow - 20} dB',
          onChanged: (val) => patchService.updateMasterParameter('master_eq_low', val),
        ),
        const SizedBox(height: 6),
        _buildSliderTile(
          label: 'MID GAIN',
          value: patchService.masterEqMidGain,
          min: 0,
          max: 40,
          displayValue: '${patchService.masterEqMidGain - 20} dB',
          onChanged: (val) => patchService.updateMasterParameter('master_eq_mid_gain', val),
        ),
        const SizedBox(height: 6),
        _buildMidFreqAndQRow(),
        const SizedBox(height: 6),
        _buildSliderTile(
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

  Widget _buildMidFreqAndQRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildDropdownCard(
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
    required String label,
    required int valueIndex,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white54)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: valueIndex,
              isDense: true,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E2C),
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
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
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
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white54),
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
