import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Interactive Tap Tempo & Metronome Visual Pulsing Pad
/// Blinks in lockstep with the configured BPM and requires minimum 4 taps to set tempo.
class MetronomeTapPad extends StatefulWidget {
  final PatchService patchService;
  final AppColorScheme colors;
  final bool isActive;
  final ValueChanged<int>? onTempoCalculated;
  final DateTime Function() clock;

  const MetronomeTapPad({
    super.key,
    required this.patchService,
    required this.colors,
    required this.isActive,
    this.onTempoCalculated,
    this.clock = DateTime.now,
  });

  @override
  State<MetronomeTapPad> createState() => _MetronomeTapPadState();
}

class _MetronomeTapPadState extends State<MetronomeTapPad>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseAnim;
  final List<int> _tapTimes = [];
  int _currentBeat = 1;
  String _tapStatusText = 'Toca el pad 4 veces al ritmo para sincronizar';
  bool _justSynced = false;

  int _tempoMs(int bpm) => (60000 / bpm.clamp(20, 250)).round();

  int _getBeatsPerMeasure(int beatIdx) {
    const counts = [1, 2, 3, 4, 5, 6, 7, 5, 6, 7];
    if (beatIdx >= 0 && beatIdx < counts.length) return counts[beatIdx];
    return 4;
  }

  @override
  void initState() {
    super.initState();
    final bpm = widget.patchService.systemSettings.metronomeTempo.clamp(20, 250);
    _pulseAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _tempoMs(bpm)),
    );
    _pulseAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.isActive && mounted) {
          final maxBeats = _getBeatsPerMeasure(widget.patchService.systemSettings.metronomeBeat);
          setState(() {
            _currentBeat = (_currentBeat % maxBeats) + 1;
          });
          _pulseAnim.forward(from: 0.0);
        }
      }
    });
    if (widget.isActive) {
      _pulseAnim.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MetronomeTapPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bpm = widget.patchService.systemSettings.metronomeTempo.clamp(20, 250);
    _pulseAnim.duration = Duration(milliseconds: _tempoMs(bpm));
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseAnim.forward(from: 0.0);
      } else {
        _pulseAnim.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  void _handleTap() {
    final now = widget.clock().millisecondsSinceEpoch;
    // Reset if elapsed time between taps exceeds 2500ms
    if (_tapTimes.isNotEmpty && (now - _tapTimes.last > 2500)) {
      _tapTimes.clear();
    }
    _tapTimes.add(now);
    if (_tapTimes.length > 8) {
      _tapTimes.removeAt(0);
    }

    // Synchronize the visual pulse moment and phase immediately
    _pulseAnim.forward(from: 0.0);
    _currentBeat = 1;

    if (_tapTimes.length < 4) {
      setState(() {
        _tapStatusText = 'Golpe ${_tapTimes.length} de 4... sigue el ritmo';
        _justSynced = false;
      });
    } else {
      // 4 or more taps: calculate average interval
      final totalInterval = _tapTimes.last - _tapTimes.first;
      final avgInterval = totalInterval / (_tapTimes.length - 1);
      final newBpm = (60000.0 / avgInterval).round().clamp(20, 250);

      widget.patchService.updateSystemParameter('metronome_tempo', newBpm);
      widget.patchService.updateMasterParameter('master_bpm', newBpm);
      widget.onTempoCalculated?.call(newBpm);

      _pulseAnim.duration = Duration(milliseconds: _tempoMs(newBpm));
      _pulseAnim.forward(from: 0.0);

      setState(() {
        _tapStatusText = '¡TEMPO SINCRONIZADO: $newBpm BPM! (${_tapTimes.length} golpes)';
        _justSynced = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final sys = widget.patchService.systemSettings;
    final maxBeats = _getBeatsPerMeasure(sys.metronomeBeat);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final flash = widget.isActive ? (1.0 - _pulseAnim.value).clamp(0.0, 1.0) : 0.0;
        final isDownbeat = _currentBeat == 1;
        final beatColor = isDownbeat ? colors.accent : colors.primary;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: beatColor.withValues(alpha: 0.3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Color.lerp(colors.cardBackground, beatColor.withValues(alpha: 0.22), flash * 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: flash > 0.15 ? beatColor : colors.borderSubtle,
                  width: flash > 0.15 ? 2.0 : 1.2,
                ),
                boxShadow: [
                  if (widget.isActive && flash > 0.1)
                    BoxShadow(
                      color: beatColor.withValues(alpha: 0.4 * flash),
                      blurRadius: 16 * flash,
                      spreadRadius: 2 * flash,
                    ),
                ],
              ),
              child: Column(
                children: [
                  // Pad Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.touch_app, size: 16, color: beatColor),
                          const SizedBox(width: 6),
                          Text(
                            'PAD DE TAP TEMPO Y PULSO VISUAL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: 0.6),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tapTimes.length >= 4 ? const Color(0xFF00FF88).withValues(alpha: 0.2) : colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _tapTimes.length >= 4 ? const Color(0xFF00FF88) : colors.borderSubtle,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _tapTimes.isEmpty
                              ? 'MÍNIMO 4 GOLPES'
                              : (_tapTimes.length < 4 ? 'GOLPES: ${_tapTimes.length} / 4' : '✓ SINCRONIZADO'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _tapTimes.length >= 4 ? (colors.isDark ? const Color(0xFF00FF88) : const Color(0xFF15803D)) : colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Large BPM Readout
                  Text(
                    '${sys.metronomeTempo}',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: beatColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Text(
                    'BPM (PULSOS POR MINUTO)',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),

                  // Measure Beat Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(maxBeats, (idx) {
                      final isCurrentDot = widget.isActive && (_currentBeat == idx + 1);
                      final isDownDot = idx == 0;
                      final dotColor = isDownDot ? colors.accent : colors.primary;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 60),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrentDot ? 12 : 8,
                        height: isCurrentDot ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrentDot ? dotColor : colors.sliderInactiveTrack,
                          boxShadow: [
                            if (isCurrentDot)
                              BoxShadow(color: dotColor.withValues(alpha: 0.7), blurRadius: 8, spreadRadius: 1),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  // Feedback / Instruction Text
                  Text(
                    _tapStatusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _justSynced ? (colors.isDark ? const Color(0xFF00FF88) : const Color(0xFF15803D)) : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
