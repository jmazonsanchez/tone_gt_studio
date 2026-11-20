import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Touch-friendly Tempo & Key Card for Master Workbench.
/// Includes large BPM counter, step nudges, giant pulsing Tap Tempo button, and Key selector.
class MasterTempoCard extends StatefulWidget {
  final PatchService patchService;
  final AppColorScheme colors;
  final DateTime Function() clock;

  static const List<String> musicalKeys = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'
  ];

  const MasterTempoCard({
    super.key,
    required this.patchService,
    required this.colors,
    this.clock = DateTime.now,
  });

  @override
  State<MasterTempoCard> createState() => _MasterTempoCardState();
}

class _MasterTempoCardState extends State<MasterTempoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<int> _tapTimes = [];

  @override
  void initState() {
    super.initState();
    final bpm = widget.patchService.masterBpm.clamp(40, 250);
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 / bpm).round()),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MasterTempoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bpm = widget.patchService.masterBpm.clamp(40, 250);
    _pulseController.duration = Duration(milliseconds: (60000 / bpm).round());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapTempo() {
    final now = widget.clock().millisecondsSinceEpoch;
    if (_tapTimes.isNotEmpty && (now - _tapTimes.last > 2000)) {
      _tapTimes.clear();
    }
    _tapTimes.add(now);
    if (_tapTimes.length > 5) _tapTimes.removeAt(0);

    if (_tapTimes.length >= 2) {
      int totalDelta = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalDelta += _tapTimes[i] - _tapTimes[i - 1];
      }
      final avgDelta = totalDelta / (_tapTimes.length - 1);
      if (avgDelta > 0) {
        final calculatedBpm = (60000 / avgDelta).round().clamp(40, 250);
        widget.patchService.updateMasterParameter('master_bpm', calculatedBpm);
      }
    }
    _pulseController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00ADB5);
    final colors = widget.colors;
    final bpm = widget.patchService.masterBpm;
    final keyIdx = widget.patchService.masterKey.clamp(0, MasterTempoCard.musicalKeys.length - 1);

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.speed_rounded, size: 14, color: teal),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'TEMPO & TONO',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepBtn(Icons.remove, () => widget.patchService.updateMasterParameter('master_bpm', (bpm - 1).clamp(40, 250))),
              Text('$bpm BPM', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: teal)),
              _buildStepBtn(Icons.add, () => widget.patchService.updateMasterParameter('master_bpm', (bpm + 1).clamp(40, 250))),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                return InkWell(
                  onTap: _handleTapTempo,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.lerp(teal.withValues(alpha: 0.15), teal.withValues(alpha: 0.35), pulse),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color.lerp(teal.withValues(alpha: 0.4), teal, pulse)!,
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 20, color: teal),
                          SizedBox(height: 3),
                          Text('TAP TEMPO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: teal, letterSpacing: 0.8)),
                          Text('Toca el ritmo', style: TextStyle(fontSize: 8.5, color: teal)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          _buildKeySelector(colors, keyIdx),
        ],
      ),
    );
  }

  Widget _buildKeySelector(AppColorScheme colors, int currentIdx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Text('KEY:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentIdx,
                isDense: true,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colors.textPrimary),
                dropdownColor: colors.surface,
                items: MasterTempoCard.musicalKeys.asMap().entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => v != null ? widget.patchService.updateMasterParameter('master_key', v) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: widget.colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: widget.colors.borderSubtle),
        ),
        child: Icon(icon, size: 16, color: widget.colors.textSecondary),
      ),
    );
  }
}
