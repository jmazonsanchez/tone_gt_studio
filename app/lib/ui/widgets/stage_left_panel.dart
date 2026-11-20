import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../layout/responsive_breakpoints.dart';
import '../theme/app_theme.dart';
import 'master_settings_modal.dart';

/// Studio Master Console Panel for Boss GT-1B.
/// Direct live access to Patch Level, Master BPM, Master Key, and Master 4-Band Parametric EQ.
class StageLeftPanel extends StatelessWidget {
  final PatchService patchService;
  final StageBreakpoint breakpoint;
  final VoidCallback? onOpenMaster;

  static const List<String> musicalKeys = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'];
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
    this.onOpenMaster,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isCompact = breakpoint == StageBreakpoint.compact;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.isDark ? const [Color(0xFF13131E), Color(0xFF161624)] : const [Colors.white, Color(0xFFF8FAFC)],
        ),
        border: Border(right: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, colors),
          const SizedBox(height: 8),
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
                    accentColor: const Color(0xFFFF9800),
                    onChanged: (val) => patchService.updateMasterParameter('patch_level', val),
                  ),
                  const SizedBox(height: 6),
                  _buildTempoAndKeyRow(colors),
                  const SizedBox(height: 8),
                  _buildMasterEqSection(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors) {
    const amber = Color(0xFFFF9800);
    return InkWell(
      onTap: onOpenMaster ?? () => MasterSettingsModal.show(context, patchService),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF0F0F18) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: amber, boxShadow: [BoxShadow(color: amber.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)]),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('CONFIGURACIÓN MASTER', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.7, color: amber)),
            ),
            Icon(Icons.tune_rounded, size: 12, color: amber.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildTempoAndKeyRow(AppColorScheme colors) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildSliderTile(
            colors: colors,
            label: 'BPM',
            value: patchService.masterBpm,
            min: 40,
            max: 250,
            displayValue: '${patchService.masterBpm}',
            accentColor: const Color(0xFF00ADB5),
            onChanged: (val) => patchService.updateMasterParameter('master_bpm', val),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: _buildDropdownCard(
            colors: colors,
            label: 'KEY',
            valueIndex: patchService.masterKey.clamp(0, musicalKeys.length - 1),
            items: musicalKeys,
            accentColor: const Color(0xFF00ADB5),
            onChanged: (val) => patchService.updateMasterParameter('master_key', val),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterEqSection(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF10101A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.equalizer_rounded, size: 12, color: colors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text('MASTER 4-BAND EQ', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: colors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _buildEqBandTile(colors, 'LOW GAIN', patchService.masterEqLow, (v) => patchService.updateMasterParameter('master_eq_low', v)),
          const SizedBox(height: 4),
          _buildEqBandTile(colors, 'MID GAIN', patchService.masterEqMidGain, (v) => patchService.updateMasterParameter('master_eq_mid_gain', v)),
          const SizedBox(height: 4),
          _buildMidFreqAndQRow(colors),
          const SizedBox(height: 4),
          _buildEqBandTile(colors, 'HIGH GAIN', patchService.masterEqHigh, (v) => patchService.updateMasterParameter('master_eq_high', v)),
        ],
      ),
    );
  }

  Widget _buildEqBandTile(AppColorScheme colors, String label, int value, ValueChanged<int> onChanged) {
    final delta = value - 20;
    final color = delta > 0 ? const Color(0xFFFF9800) : (delta < 0 ? const Color(0xFF00ADB5) : colors.textSecondary);
    final sign = delta > 0 ? '+' : '';
    return _buildSliderTile(colors: colors, label: label, value: value, min: 0, max: 40, displayValue: '$sign$delta dB', accentColor: color, onChanged: onChanged);
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
            accentColor: const Color(0xFFFF9800),
            onChanged: (val) => patchService.updateMasterParameter('master_eq_mid_freq', val),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: _buildDropdownCard(
            colors: colors,
            label: 'MID Q',
            valueIndex: patchService.masterEqMidQ.clamp(0, midQLabels.length - 1),
            items: midQLabels,
            accentColor: const Color(0xFFFF9800),
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
    required Color accentColor,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(7), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 0.3)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: valueIndex,
              isDense: true,
              isExpanded: true,
              dropdownColor: colors.surface,
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10),
              items: List.generate(items.length, (idx) => DropdownMenuItem(value: idx, child: Text(items[idx]))),
              onChanged: (val) => val != null ? onChanged(val) : null,
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
    required Color accentColor,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(7), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 0.2)),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(displayValue, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: accentColor)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 7),
              activeTrackColor: accentColor,
              inactiveTrackColor: colors.isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              thumbColor: accentColor,
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
