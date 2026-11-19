import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../services/patch_service.dart';

/// Metronome Configuration Tab for Boss GT-1B
class SystemMetronomeTab extends StatelessWidget {
  final PatchService patchService;

  const SystemMetronomeTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final sys = patchService.systemSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Metronome ON/OFF Master Switch
          _buildPowerSwitch(sys),
          const SizedBox(height: 14),

          // 2. Tempo BPM & Beat Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTempoCard(sys),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildBeatCard(sys),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Metronome Output Level
          _buildLevelCard(sys),
        ],
      ),
    );
  }

  Widget _buildPowerSwitch(SystemSettings sys) {
    final active = sys.metronomeOn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? const Color(0xFF00ADB5) : Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: active ? const Color(0xFF00ADB5) : Colors.white38, size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('METRÓNOMO INTERNO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  Text(active ? 'ACTIVO (SONANDO EN SALIDA)' : 'APAGADO', style: TextStyle(fontSize: 10, color: active ? const Color(0xFF00ADB5) : Colors.white38)),
                ],
              ),
            ],
          ),
          Switch(
            value: active,
            activeColor: const Color(0xFF00ADB5),
            onChanged: (val) => patchService.updateSystemParameter('metronome_on', val ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoCard(SystemSettings sys) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TEMPO (BPM)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
              Text('${sys.metronomeTempo}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF00ADB5))),
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
              value: sys.metronomeTempo.clamp(20, 250).toDouble(),
              min: 20,
              max: 250,
              onChanged: (v) => patchService.updateSystemParameter('metronome_tempo', v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeatCard(SystemSettings sys) {
    final beatIdx = sys.metronomeBeat.clamp(0, SystemSettings.beatLabels.length - 1);
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
          const Text('COMPÁS (BEAT)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: beatIdx,
              isDense: true,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 13),
              items: List.generate(SystemSettings.beatLabels.length, (idx) {
                return DropdownMenuItem(value: idx, child: Text(SystemSettings.beatLabels[idx]));
              }),
              onChanged: (val) {
                if (val != null) patchService.updateSystemParameter('metronome_beat', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(SystemSettings sys) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('VOLUMEN METRÓNOMO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
              Text('${sys.metronomeLevel} %', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00ADB5))),
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
              value: sys.metronomeLevel.clamp(0, 100).toDouble(),
              min: 0,
              max: 100,
              onChanged: (v) => patchService.updateSystemParameter('metronome_level', v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
