import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../services/patch_service.dart';

/// Global Audio I/O & Global EQ Tab for Boss GT-1B
class SystemGlobalTab extends StatelessWidget {
  final PatchService patchService;

  static const List<String> midFreqLabels = [
    '100 Hz', '125 Hz', '160 Hz', '200 Hz', '250 Hz', '315 Hz', '400 Hz', '500 Hz',
    '630 Hz', '800 Hz', '1.0 kHz', '1.25 kHz', '1.6 kHz', '2.0 kHz', '2.5 kHz', '3.15 kHz',
    '4.0 kHz', '5.0 kHz', '6.3 kHz', '8.0 kHz', '10.0 kHz'
  ];

  static const List<String> midQLabels = ['0.5', '1', '2', '4', '8', '16'];

  const SystemGlobalTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final sys = patchService.systemSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Output Select & Input Level
          _buildIoSection(sys),
          const SizedBox(height: 14),

          // 2. Global 4-Band Parametric EQ
          _buildGlobalEqSection(sys),
          const SizedBox(height: 14),

          // 3. Total Reverb Level
          _buildSliderCard(
            label: 'TOTAL REVERB LEVEL',
            value: sys.totalReverb,
            min: 0,
            max: 100,
            displayValue: '${sys.totalReverb} %',
            onChanged: (val) => patchService.updateSystemParameter('total_reverb', val),
          ),
        ],
      ),
    );
  }

  Widget _buildIoSection(SystemSettings sys) {
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
          const Text('RUTEO DE SALIDA Y ENTRADA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OUTPUT SELECT', style: TextStyle(fontSize: 9, color: Colors.white70)),
                    const SizedBox(height: 2),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: sys.outputSelect.clamp(0, SystemSettings.outputSelectOptions.length - 1),
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E1E2C),
                        style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 11),
                        items: List.generate(SystemSettings.outputSelectOptions.length, (idx) {
                          return DropdownMenuItem(value: idx, child: Text(SystemSettings.outputSelectOptions[idx]));
                        }),
                        onChanged: (val) {
                          if (val != null) patchService.updateSystemParameter('output_select', val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildSliderCard(
                  label: 'INPUT LEVEL',
                  value: sys.inputLevel,
                  min: 0,
                  max: 20,
                  displayValue: '${sys.inputLevel - 10} dB',
                  onChanged: (val) => patchService.updateSystemParameter('input_level', val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalEqSection(SystemSettings sys) {
    final freqIdx = sys.eqMidFreq.clamp(0, midFreqLabels.length - 1);
    final qIdx = sys.eqMidQ.clamp(0, midQLabels.length - 1);

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
          const Text('GLOBAL 4-BAND EQ (HARDWARE MASTER)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSliderCard(
                  label: 'LOW GAIN',
                  value: sys.eqLowGain,
                  min: 0,
                  max: 40,
                  displayValue: '${sys.eqLowGain - 20} dB',
                  onChanged: (v) => patchService.updateSystemParameter('global_eq_low', v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSliderCard(
                  label: 'MID GAIN',
                  value: sys.eqMidGain,
                  min: 0,
                  max: 40,
                  displayValue: '${sys.eqMidGain - 20} dB',
                  onChanged: (v) => patchService.updateSystemParameter('global_eq_mid_gain', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MID FREQ', style: TextStyle(fontSize: 8, color: Colors.white54)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: freqIdx,
                          isDense: true,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E2C),
                          style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 11),
                          items: List.generate(midFreqLabels.length, (i) => DropdownMenuItem(value: i, child: Text(midFreqLabels[i]))),
                          onChanged: (v) {
                            if (v != null) patchService.updateSystemParameter('global_eq_mid_freq', v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MID Q', style: TextStyle(fontSize: 8, color: Colors.white54)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: qIdx,
                          isDense: true,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E2C),
                          style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 11),
                          items: List.generate(midQLabels.length, (i) => DropdownMenuItem(value: i, child: Text(midQLabels[i]))),
                          onChanged: (v) {
                            if (v != null) patchService.updateSystemParameter('global_eq_mid_q', v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSliderCard(
                  label: 'HIGH GAIN',
                  value: sys.eqHighGain,
                  min: 0,
                  max: 40,
                  displayValue: '${sys.eqHighGain - 20} dB',
                  onChanged: (v) => patchService.updateSystemParameter('global_eq_high', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
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
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white54))),
              Text(displayValue, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00ADB5))),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: Color(0xFF00ADB5),
              inactiveTrackColor: Colors.white10,
              thumbColor: Color(0xFF00ADB5),
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
