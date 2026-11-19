import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Metronome Configuration Tab for Boss GT-1B
class SystemMetronomeTab extends StatelessWidget {
  final PatchService patchService;

  const SystemMetronomeTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sys = patchService.systemSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPowerSwitch(sys, colors),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(flex: 3, child: _buildTempoCard(sys, colors)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildBeatCard(sys, colors)),
            ],
          ),
          const SizedBox(height: 14),
          _buildLevelCard(sys, colors),
        ],
      ),
    );
  }

  Widget _buildPowerSwitch(SystemSettings sys, AppColorScheme colors) {
    final active = sys.metronomeOn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? colors.primary : colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: active ? colors.primary : colors.textMuted, size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('METRÓNOMO INTERNO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                  Text(active ? 'ACTIVO (SONANDO EN SALIDA)' : 'APAGADO', style: TextStyle(fontSize: 10, color: active ? colors.primary : colors.textMuted)),
                ],
              ),
            ],
          ),
          Switch(
            value: active,
            activeColor: colors.primary,
            onChanged: (val) => patchService.updateSystemParameter('metronome_on', val ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoCard(SystemSettings sys, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TEMPO (BPM)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
              Text('${sys.metronomeTempo}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colors.primary)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.sliderInactiveTrack,
              thumbColor: colors.primary,
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

  Widget _buildBeatCard(SystemSettings sys, AppColorScheme colors) {
    final beatIdx = sys.metronomeBeat.clamp(0, SystemSettings.beatLabels.length - 1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPÁS (BEAT)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: beatIdx,
              isDense: true,
              isExpanded: true,
              dropdownColor: colors.surfaceElevated,
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildLevelCard(SystemSettings sys, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VOLUMEN METRÓNOMO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
              Text('${sys.metronomeLevel} %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.sliderInactiveTrack,
              thumbColor: colors.primary,
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
