import 'package:flutter/material.dart';
import '../../services/patch_service.dart';

/// Modal dialog for Boss GT-1B Master settings:
/// Patch Level, Master BPM, Master Key, and Master 4-Band parametric EQ.
class MasterSettingsModal extends StatelessWidget {
  final PatchService patchService;

  static const List<String> musicalKeys = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'
  ];

  static const List<String> midFreqLabels = [
    '100 Hz', '125 Hz', '160 Hz', '200 Hz', '250 Hz', '315 Hz', '400 Hz', '500 Hz',
    '630 Hz', '800 Hz', '1.0 kHz', '1.25 kHz', '1.6 kHz', '2.0 kHz', '2.5 kHz', '3.15 kHz',
    '4.0 kHz', '5.0 kHz', '6.3 kHz', '8.0 kHz', '10.0 kHz'
  ];

  static const List<String> midQLabels = ['0.5', '1', '2', '4', '8', '16'];

  const MasterSettingsModal({super.key, required this.patchService});

  static Future<void> show(BuildContext context, PatchService patchService) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MasterSettingsModal(patchService: patchService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: patchService,
      builder: (context, _) {
        return Dialog(
          backgroundColor: const Color(0xFF14141E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildLevelAndTempoRow(),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                _buildMasterEqSection(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check, size: 16, color: Color(0xFFFF9800)),
                    label: const Text(
                      'CERRAR',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFFFF9800), size: 22),
            SizedBox(width: 8),
            Text(
              'MASTER & GLOBAL EQ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildLevelAndTempoRow() {
    return Row(
      children: [
        // Patch Level
        Expanded(
          flex: 2,
          child: _buildSliderTile(
            label: 'PATCH LEVEL',
            value: patchService.patchLevel,
            min: 0,
            max: 100,
            displayValue: '${patchService.patchLevel}',
            onChanged: (val) => patchService.updateMasterParameter('patch_level', val),
          ),
        ),
        const SizedBox(width: 14),
        // BPM
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
        const SizedBox(width: 14),
        // Key
        Expanded(
          child: _buildKeySelector(),
        ),
      ],
    );
  }

  Widget _buildKeySelector() {
    final keyIdx = patchService.masterKey.clamp(0, musicalKeys.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KEY',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: keyIdx,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A26),
              style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 13),
              items: List.generate(musicalKeys.length, (idx) {
                return DropdownMenuItem(value: idx, child: Text(musicalKeys[idx]));
              }),
              onChanged: (val) {
                if (val != null) {
                  patchService.updateMasterParameter('master_key', val);
                }
              },
            ),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Color(0xFFFF9800),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSliderTile(
                label: 'LOW GAIN',
                value: patchService.masterEqLow,
                min: 0,
                max: 40,
                displayValue: '${patchService.masterEqLow - 20} dB',
                onChanged: (val) => patchService.updateMasterParameter('master_eq_low', val),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSliderTile(
                label: 'MID GAIN',
                value: patchService.masterEqMidGain,
                min: 0,
                max: 40,
                displayValue: '${patchService.masterEqMidGain - 20} dB',
                onChanged: (val) => patchService.updateMasterParameter('master_eq_mid_gain', val),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSliderTile(
                label: 'HIGH GAIN',
                value: patchService.masterEqHigh,
                min: 0,
                max: 40,
                displayValue: '${patchService.masterEqHigh - 20} dB',
                onChanged: (val) => patchService.updateMasterParameter('master_eq_high', val),
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54),
              ),
              Text(
                displayValue,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
              ),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
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
