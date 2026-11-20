import 'package:flutter/material.dart';
import '../../domain/gt1b_catalog.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Modal dialog for Boss GT-1B Master settings:
/// Patch Level, Master BPM, Master Key, and Master 4-Band parametric EQ.
class MasterSettingsModal extends StatelessWidget {
  final PatchService patchService;

  static const List<String> musicalKeys = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'];
  static const List<String> midFreqLabels = Gt1bCatalog.eqMidFreqOptions;
  static const List<String> midQLabels = Gt1bCatalog.eqMidQOptions;

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
    final colors = AppTheme.of(context);
    const amber = Color(0xFFFF9800);

    return AnimatedBuilder(
      animation: patchService,
      builder: (context, _) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.borderSubtle)),
          child: Container(
            width: 580,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.08), blurRadius: 16)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, colors, amber),
                const SizedBox(height: 16),
                _buildLevelAndTempoRow(colors),
                const SizedBox(height: 14),
                Divider(color: colors.borderSubtle, height: 1),
                const SizedBox(height: 14),
                _buildMasterEqSection(colors, amber),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 16, color: amber),
                    label: const Text('CERRAR', style: TextStyle(color: amber, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors, Color amber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: amber, boxShadow: [BoxShadow(color: amber.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)]),
            ),
            const SizedBox(width: 8),
            Text('MASTER & GLOBAL EQ', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          ],
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildLevelAndTempoRow(AppColorScheme colors) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildSliderTile(
            colors: colors,
            label: 'PATCH LEVEL',
            value: patchService.patchLevel,
            min: 0,
            max: 100,
            displayValue: '${patchService.patchLevel}',
            accentColor: const Color(0xFFFF9800),
            onChanged: (val) => patchService.updateMasterParameter('patch_level', val),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
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
        const SizedBox(width: 10),
        Expanded(flex: 2, child: _buildKeySelector(colors)),
      ],
    );
  }

  Widget _buildKeySelector(AppColorScheme colors) {
    final keyIdx = patchService.masterKey.clamp(0, musicalKeys.length - 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KEY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 0.4)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: keyIdx,
              isExpanded: true,
              isDense: true,
              dropdownColor: colors.surface,
              style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.w900, fontSize: 12),
              items: List.generate(musicalKeys.length, (idx) => DropdownMenuItem(value: idx, child: Text(musicalKeys[idx]))),
              onChanged: (val) => val != null ? patchService.updateMasterParameter('master_key', val) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterEqSection(AppColorScheme colors, Color amber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.equalizer_rounded, size: 14, color: colors.textMuted),
            const SizedBox(width: 6),
            Text('MASTER 4-BAND EQ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: colors.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildEqSliderTile(colors, 'LOW GAIN', patchService.masterEqLow, (v) => patchService.updateMasterParameter('master_eq_low', v))),
            const SizedBox(width: 8),
            Expanded(child: _buildEqSliderTile(colors, 'MID GAIN', patchService.masterEqMidGain, (v) => patchService.updateMasterParameter('master_eq_mid_gain', v))),
            const SizedBox(width: 8),
            Expanded(child: _buildEqSliderTile(colors, 'HIGH GAIN', patchService.masterEqHigh, (v) => patchService.updateMasterParameter('master_eq_high', v))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDropdownTile(
                colors: colors,
                label: 'MID FREQ',
                valueIndex: patchService.masterEqMidFreq.clamp(0, midFreqLabels.length - 1),
                items: midFreqLabels,
                onChanged: (v) => patchService.updateMasterParameter('master_eq_mid_freq', v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildDropdownTile(
                colors: colors,
                label: 'MID Q',
                valueIndex: patchService.masterEqMidQ.clamp(0, midQLabels.length - 1),
                items: midQLabels,
                onChanged: (v) => patchService.updateMasterParameter('master_eq_mid_q', v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEqSliderTile(AppColorScheme colors, String label, int value, ValueChanged<int> onChanged) {
    final delta = value - 20;
    final color = delta > 0 ? const Color(0xFFFF9800) : (delta < 0 ? const Color(0xFF00ADB5) : colors.textSecondary);
    final sign = delta > 0 ? '+' : '';
    return _buildSliderTile(colors: colors, label: label, value: value, min: 0, max: 40, displayValue: '$sign$delta dB', accentColor: color, onChanged: onChanged);
  }

  Widget _buildDropdownTile({required AppColorScheme colors, required String label, required int valueIndex, required List<String> items, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 0.3)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: valueIndex,
              isExpanded: true,
              isDense: true,
              dropdownColor: colors.surface,
              style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w900, fontSize: 11),
              items: List.generate(items.length, (idx) => DropdownMenuItem(value: idx, child: Text(items[idx]))),
              onChanged: (val) => val != null ? onChanged(val) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({required AppColorScheme colors, required String label, required int value, required int min, required int max, required String displayValue, required Color accentColor, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 0.3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(displayValue, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: accentColor)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: accentColor,
              inactiveTrackColor: colors.isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              thumbColor: accentColor,
            ),
            child: Slider(value: value.clamp(min, max).toDouble(), min: min.toDouble(), max: max.toDouble(), onChanged: (v) => onChanged(v.round())),
          ),
        ],
      ),
    );
  }
}
