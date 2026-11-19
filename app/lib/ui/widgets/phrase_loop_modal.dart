import 'package:flutter/material.dart';
import '../../models/phrase_loop.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Interactive Phrase Loop (Looper 32s) Controller for Boss GT-1B.
/// Features configurable pre-roll power-on timer (in seconds) and auto-stop duration.
class PhraseLoopModal extends StatelessWidget {
  final PatchService patchService;
  final VoidCallback onClose;

  const PhraseLoopModal({super.key, required this.patchService, required this.onClose});

  static Future<void> show(BuildContext context, PatchService patchService) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: patchService,
        builder: (context, _) => PhraseLoopModal(
          patchService: patchService,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final status = patchService.looperStatus;
    final settings = patchService.phraseLoopSettings;
    final elapsed = patchService.looperElapsedSeconds;
    final total = status == LooperStatus.playing || status == LooperStatus.overdubbing
        ? patchService.recordedLoopDuration
        : (settings.maxDurationSeconds > 0 ? settings.maxDurationSeconds.toDouble() : 32.0);

    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 12),
            _buildStatusMeter(status, elapsed, total, colors),
            const SizedBox(height: 12),
            _buildMainTransportButton(status, settings, colors),
            const SizedBox(height: 12),
            _buildSecondaryTransportRow(status, colors),
            const SizedBox(height: 14),
            _buildTimerSelectors(settings, colors),
            const SizedBox(height: 12),
            _buildHardwareLevelRow(settings, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.all_inclusive, color: colors.accent, size: 22),
            const SizedBox(width: 8),
            Text(
              'PHRASE LOOP (LOOPER 32s GT-1B)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.9, color: colors.textPrimary),
            ),
          ],
        ),
        IconButton(onPressed: onClose, icon: Icon(Icons.close, color: colors.textMuted, size: 20), visualDensity: VisualDensity.compact),
      ],
    );
  }

  (Color, String) _resolveStatusMeta(LooperStatus status, AppColorScheme colors) {
    switch (status) {
      case LooperStatus.countdown:
        return (Colors.purpleAccent, 'CUENTA REGRESIVA: ${patchService.looperCountdownRemaining}s');
      case LooperStatus.recording:
        return (Colors.redAccent, 'GRABANDO EN VIVO (REC)');
      case LooperStatus.playing:
        return (const Color(0xFF00ADB5), 'REPRODUCIENDO LOOP (PLAY)');
      case LooperStatus.overdubbing:
        return (Colors.amber, 'SOBREGRAVANDO CAPA (DUB)');
      case LooperStatus.stopped:
        return (colors.textMuted, patchService.recordedLoopDuration > 0 ? 'LOOP EN MEMORIA (DETENIDO)' : 'LOOPER LISTO (VACÍO)');
    }
  }

  Widget _buildStatusMeter(LooperStatus status, double elapsed, double total, AppColorScheme colors) {
    final (ledColor, statusText) = _resolveStatusMeta(status, colors);
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ledColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: ledColor, boxShadow: [BoxShadow(color: ledColor, blurRadius: 6, spreadRadius: 1)]),
                  ),
                  const SizedBox(width: 8),
                  Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ledColor)),
                ],
              ),
              Text('${elapsed.toStringAsFixed(1)}s / ${total.toStringAsFixed(1)}s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: colors.surfaceVariant, color: ledColor, borderRadius: BorderRadius.circular(3)),
        ],
      ),
    );
  }

  Widget _buildMainTransportButton(LooperStatus status, PhraseLoopSettings settings, AppColorScheme colors) {
    if (status == LooperStatus.countdown) {
      return SizedBox(
        height: 46,
        child: ElevatedButton.icon(
          onPressed: () => patchService.stopLooper(),
          icon: const Icon(Icons.close, size: 20),
          label: Text('CANCELAR CUENTA REGRESIVA (${patchService.looperCountdownRemaining}s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      );
    }

    final (action, icon, label, bg) = switch (status) {
      LooperStatus.recording => (patchService.switchToPlayback, Icons.play_arrow, 'CERRAR Y REPRODUCIR (PLAY)', const Color(0xFF00ADB5)),
      LooperStatus.playing => (patchService.switchToOverdub, Icons.fiber_manual_record, 'SOBREGRAVAR NUEVA CAPA (DUB)', Colors.amber.shade800),
      LooperStatus.overdubbing => (patchService.switchToPlayback, Icons.check, 'FINALIZAR CAPA (PLAY)', const Color(0xFF00ADB5)),
      _ => (
          patchService.startLooperWithTimer,
          Icons.fiber_manual_record,
          settings.startTimerSeconds > 0 ? 'ENCENDER Y GRABAR (${settings.startTimerSeconds}s Timer)' : 'ENCENDER Y GRABAR',
          Colors.redAccent,
        ),
    };

    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8)),
        style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _buildSecondaryTransportRow(LooperStatus status, AppColorScheme colors) {
    final canStop = status != LooperStatus.stopped;
    final hasPhrase = patchService.recordedLoopDuration > 0 || status != LooperStatus.stopped;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canStop ? () => patchService.stopLooper() : null,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('DETENER (STOP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            style: OutlinedButton.styleFrom(foregroundColor: colors.textPrimary, side: BorderSide(color: colors.borderSubtle)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasPhrase ? () => patchService.clearLooper() : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('BORRAR LOOP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: BorderSide(color: colors.borderSubtle)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSelectors(PhraseLoopSettings settings, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectorHeader(Icons.timer_outlined, 'TEMPORIZADOR DE ENCENDIDO (PRE-ROLL)', colors.accent, colors),
          const SizedBox(height: 6),
          _buildChipRow([0, 2, 3, 5, 10], settings.startTimerSeconds, (s) => patchService.updateLooperStartTimer(s), (s) => s == 0 ? '0s (Directo)' : '${s}s', colors.accent),
          const SizedBox(height: 10),
          _buildSelectorHeader(Icons.timelapse, 'DURACIÓN DE GRABACIÓN AUTOMÁTICA', colors.primary, colors),
          const SizedBox(height: 6),
          _buildChipRow([0, 4, 8, 16, 32], settings.maxDurationSeconds, (s) => patchService.updateLooperDurationTimer(s), (s) => s == 0 ? 'Libre (32s)' : '${s}s', colors.primary),
        ],
      ),
    );
  }

  Widget _buildSelectorHeader(IconData icon, String title, Color iconColor, AppColorScheme colors) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildChipRow(List<int> values, int selected, ValueChanged<int> onSelect, String Function(int) format, Color color) {
    return Row(
      children: values.map((val) {
        final isSel = selected == val;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text(format(val), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              selected: isSel,
              selectedColor: color.withValues(alpha: 0.3),
              onSelected: (_) => onSelect(val),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHardwareLevelRow(PhraseLoopSettings settings, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: colors.cardBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text('PLAY LEVEL: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted)),
                Expanded(
                  child: Slider(
                    value: settings.playLevel.toDouble(),
                    min: 1,
                    max: 120,
                    activeColor: colors.accent,
                    onChanged: (v) => patchService.updateLooperLevel(v.round()),
                  ),
                ),
                Text('${settings.playLevel}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.accent)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              final next = settings.recMode == LooperRecMode.recPlay ? LooperRecMode.recDub : LooperRecMode.recPlay;
              patchService.updateLooperRecMode(next);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.borderSubtle)),
              child: Text(settings.recModeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
