import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Real-time Interactive Chromatic Tuner Modal for Boss GT-1B.
/// Driven by live pitch stream (7F 00 05 00) and SysEx Tuner Mode (7F 00 00 02).
class TunerModal extends StatelessWidget {
  final PatchService patchService;
  final VoidCallback onClose;

  const TunerModal({super.key, required this.patchService, required this.onClose});

  /// Open Tuner modal, putting Boss GT-1B pedal into Tuner mode and restoring Play on exit
  static Future<void> show(BuildContext context, PatchService patchService) async {
    await patchService.startTuner();
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: patchService,
        builder: (context, _) => TunerModal(
          patchService: patchService,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );

    await patchService.stopTuner();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sys = patchService.systemSettings;
    final note = sys.liveNote;
    final cents = sys.liveCents;
    final inTune = sys.inTune;

    final accentColor = inTune
        ? const Color(0xFF00FF88)
        : (cents.abs() <= 15 ? colors.primary : const Color(0xFFFF9800));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colors),
          const SizedBox(height: 10),
          _buildTunerConfigRow(sys, colors),
          const SizedBox(height: 12),
          _buildNoteDisplay(note, inTune, accentColor),
          const SizedBox(height: 6),
          Text(
            note == '---'
                ? 'Toca una cuerda del bajo para afinar'
                : (inTune ? '¡AFINADO PERFECTO!' : '${cents > 0 ? "+$cents" : "$cents"} cents'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: inTune ? const Color(0xFF00FF88) : colors.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _buildCentGauge(cents, accentColor, colors),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('♭ BEMOL (-50)', style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
              Text('EN TONO (0)', style: TextStyle(fontSize: 10, color: Color(0xFF00FF88), fontWeight: FontWeight.w900)),
              Text('SOSTENIDO (+50) ♯', style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildBassStringsBar(colors),
          const SizedBox(height: 14),
          _buildExitButton(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'AFINADOR CROMÁTICO EN VIVO',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.9, color: colors.textPrimary),
            ),
          ],
        ),
        IconButton(onPressed: onClose, icon: Icon(Icons.close, color: colors.textMuted, size: 20), visualDensity: VisualDensity.compact),
      ],
    );
  }

  Widget _buildTunerConfigRow(dynamic sys, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colors.cardBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        children: [
          Expanded(child: _buildDropdown(
            label: 'PITCH: ',
            value: sys.tunerPitch.clamp(0, 10),
            colors: colors,
            items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('${435 + i} Hz'))),
            onChanged: (v) => patchService.updateSystemParameter('tuner_pitch', v ?? 5),
          )),
          Container(width: 1, height: 18, color: colors.borderSubtle),
          const SizedBox(width: 10),
          Expanded(child: _buildDropdown(
            label: 'SALIDA: ',
            value: sys.tunerOutput.clamp(0, 2),
            colors: colors,
            items: const [DropdownMenuItem(value: 0, child: Text('MUTE')), DropdownMenuItem(value: 1, child: Text('BYPASS')), DropdownMenuItem(value: 2, child: Text('THRU'))],
            onChanged: (v) => patchService.updateSystemParameter('tuner_output', v ?? 0),
          )),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required AppColorScheme colors,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted)),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              dropdownColor: colors.surfaceElevated,
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteDisplay(String note, bool inTune, Color accentColor) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.12),
        border: Border.all(color: accentColor, width: inTune ? 3.5 : 2),
        boxShadow: inTune ? [BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 3)] : null,
      ),
      child: Center(
        child: Text(note, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildCentGauge(int cents, Color accentColor, AppColorScheme colors) {
    final normalized = ((cents + 50) / 100).clamp(0.0, 1.0);

    return Container(
      height: 18,
      width: double.infinity,
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needleX = (constraints.maxWidth - 12) * normalized;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(child: Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFF00FF88), borderRadius: BorderRadius.circular(2)))),
              Positioned(
                left: needleX,
                child: Container(
                  width: 12,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 5)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBassStringsBar(AppColorScheme colors) {
    const strings = [('B0', 11, '1.ª'), ('E1', 4, '2.ª'), ('A1', 9, '3.ª'), ('D2', 2, '4.ª'), ('G2', 7, '5.ª')];

    return Row(
      children: strings.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => patchService.setManualPitch(item.$2, 0),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(color: colors.cardBackground, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.borderSubtle)),
                child: Column(
                  children: [
                    Text(item.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.primary)),
                    Text(item.$3, style: TextStyle(fontSize: 8, color: colors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExitButton(AppColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onClose,
        icon: const Icon(Icons.check, size: 18),
        label: const Text('SALIR DEL AFINADOR (MODO PLAY)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
