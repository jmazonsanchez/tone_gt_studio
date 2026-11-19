import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';
import 'metronome_tap_pad.dart';

/// Metronome Configuration Tab for Boss GT-1B.
/// Replaces internal hardware audio click with synchronized on-screen visual pulsing
/// and a 4-tap tempo interactive pad.
class SystemMetronomeTab extends StatefulWidget {
  final PatchService patchService;
  final DateTime Function()? clock;

  const SystemMetronomeTab({super.key, required this.patchService, this.clock});

  @override
  State<SystemMetronomeTab> createState() => _SystemMetronomeTabState();
}

class _SystemMetronomeTabState extends State<SystemMetronomeTab> {
  bool _visualMetronomeActive = true;

  @override
  void initState() {
    super.initState();
    // Ensure hardware metronome audio output is off (visual only in app)
    if (widget.patchService.systemSettings.metronomeOn) {
      widget.patchService.updateSystemParameter('metronome_on', 0);
    }
  }

  void _onManualTempoChanged(int bpm) {
    widget.patchService.updateSystemParameter('metronome_tempo', bpm);
    widget.patchService.updateMasterParameter('master_bpm', bpm);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sys = widget.patchService.systemSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Visual Metronome Header Banner (No audio click)
          _buildHeaderBanner(colors),
          const SizedBox(height: 12),

          // 2. Interactive 4-Tap Tempo & Visual Pulsing Pad
          MetronomeTapPad(
            patchService: widget.patchService,
            colors: colors,
            isActive: _visualMetronomeActive,
            onTempoCalculated: (bpm) => setState(() {}),
            clock: widget.clock ?? DateTime.now,
          ),
          const SizedBox(height: 12),

          // 3. Manual BPM Slider & Measure Beat Selector
          Row(
            children: [
              Expanded(flex: 3, child: _buildTempoCard(sys, colors)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildBeatCard(sys, colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _visualMetronomeActive ? colors.primary : colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: _visualMetronomeActive ? colors.primary : colors.textMuted, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('METRÓNOMO VISUAL (EN PANTALLA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary)),
                  Text(
                    _visualMetronomeActive ? 'PULSO VISUAL ACTIVO (SIN SONIDO EN SALIDA)' : 'PULSO VISUAL PAUSADO',
                    style: TextStyle(fontSize: 9, color: _visualMetronomeActive ? colors.primary : colors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _visualMetronomeActive,
            activeColor: colors.primary,
            onChanged: (val) => setState(() => _visualMetronomeActive = val),
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
              Text('AJUSTE MANUAL TEMPO (BPM)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
              Text('${sys.metronomeTempo}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colors.primary)),
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
              onChanged: (v) => _onManualTempoChanged(v.round()),
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
                if (val != null) {
                  widget.patchService.updateSystemParameter('metronome_beat', val);
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
