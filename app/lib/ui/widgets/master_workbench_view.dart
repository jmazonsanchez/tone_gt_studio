import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';
import 'master_eq_dial.dart';
import 'master_level_card.dart';
import 'master_tempo_card.dart';

/// Finger-friendly Master Workstation View (Option 1).
/// Expands across the stage center console for Patch Level, Tap Tempo & BPM,
/// Master Key, and 4-Band Studio Parametric EQ with >= 48dp touch targets.
class MasterWorkbenchView extends StatelessWidget {
  final PatchService patchService;
  final VoidCallback? onClose;
  final DateTime Function() clock;

  static const List<String> midFreqLabels = [
    '100 Hz', '125 Hz', '160 Hz', '200 Hz', '250 Hz', '315 Hz', '400 Hz', '500 Hz',
    '630 Hz', '800 Hz', '1.0 kHz', '1.25 kHz', '1.6 kHz', '2.0 kHz', '2.5 kHz', '3.15 kHz',
    '4.0 kHz', '5.0 kHz', '6.3 kHz', '8.0 kHz', '10.0 kHz'
  ];
  static const List<String> midQLabels = ['0.5', '1', '2', '4', '8', '16'];

  const MasterWorkbenchView({
    super.key,
    required this.patchService,
    this.onClose,
    this.clock = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return AnimatedBuilder(
      animation: patchService,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colors),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MasterLevelCard(patchService: patchService, colors: colors),
                      const SizedBox(width: 10),
                      MasterTempoCard(patchService: patchService, colors: colors, clock: clock),
                      const SizedBox(width: 10),
                      _buildMasterEqCard(colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    const green = Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            'ESTACIÓN DE TRABAJO MASTER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '•  SALIDA & GLOBAL EQ',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.bold),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.undo_rounded, size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'VOLVER A EFECTOS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMasterEqCard(AppColorScheme colors) {
    const amber = Color(0xFFFF9800);
    final low = patchService.masterEqLow;
    final mid = patchService.masterEqMidGain;
    final high = patchService.masterEqHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.equalizer_rounded, size: 14, color: amber),
              const SizedBox(width: 6),
              Text(
                'MASTER 4-BAND EQ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MasterEqDial(label: 'LOW GAIN', value: low, onChanged: (v) => patchService.updateMasterParameter('master_eq_low', v)),
                const SizedBox(width: 16),
                MasterEqDial(label: 'MID GAIN', value: mid, onChanged: (v) => patchService.updateMasterParameter('master_eq_mid_gain', v)),
                const SizedBox(width: 16),
                MasterEqDial(label: 'HIGH GAIN', value: high, onChanged: (v) => patchService.updateMasterParameter('master_eq_high', v)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFreqDropdown(colors),
              const SizedBox(width: 8),
              _buildQDropdown(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreqDropdown(AppColorScheme colors) {
    final freqIdx = patchService.masterEqMidFreq.clamp(0, midFreqLabels.length - 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('FREQ:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: freqIdx,
              isDense: true,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textPrimary),
              dropdownColor: colors.surface,
              items: midFreqLabels.asMap().entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => v != null ? patchService.updateMasterParameter('master_eq_mid_freq', v) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQDropdown(AppColorScheme colors) {
    final qIdx = patchService.masterEqMidQ.clamp(0, midQLabels.length - 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Q:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: qIdx,
              isDense: true,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textPrimary),
              dropdownColor: colors.surface,
              items: midQLabels.asMap().entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => v != null ? patchService.updateMasterParameter('master_eq_mid_q', v) : null,
            ),
          ),
        ],
      ),
    );
  }
}
