import 'package:flutter/material.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import '../layout/landscape_scaffold.dart';
import '../widgets/stage_center_panel.dart';
import '../widgets/stage_header_bar.dart';
import '../widgets/stage_left_panel.dart';
import '../widgets/stage_right_panel.dart';

class StagePedalboardScreen extends StatelessWidget {
  final MidiService midi;
  final PatchService patchService;
  final bool isDemoMode;
  final VoidCallback onExitDemo;
  final VoidCallback onConnectRequest;

  const StagePedalboardScreen({
    super.key,
    required this.midi,
    required this.patchService,
    required this.isDemoMode,
    required this.onExitDemo,
    required this.onConnectRequest,
  });

  @override
  Widget build(BuildContext context) {
    final current = patchService.currentPatch;

    return LandscapeScaffold(
      header: StageHeaderBar(
        midi: midi,
        patchService: patchService,
        isDemoMode: isDemoMode,
        onExitDemo: onExitDemo,
        onConnectRequest: onConnectRequest,
      ),
      syncProgressBar: patchService.isSyncing ? _buildSyncProgress() : null,
      leftPanelBuilder: (ctx, config) => StageLeftPanel(
        patchService: patchService,
        breakpoint: config.breakpoint,
      ),
      centerPanelBuilder: (ctx, config) => StageCenterPanel(
        effects: current.effects,
        onToggleEffect: (effect) => patchService.toggleEffect(effect),
        onMoveEffect: (from, to) => patchService.moveEffect(from, to),
        breakpoint: config.breakpoint,
      ),
      rightPanelBuilder: (ctx, config) => StageRightPanel(
        isWahActive: patchService.isWahActive,
        wahPosition: patchService.wahPosition,
        footVolumeLevel: patchService.footVolumeLevel,
        onToggleWah: () => patchService.toggleWah(),
        onWahPositionChanged: (pos) => patchService.setWahPosition(pos),
        breakpoint: config.breakpoint,
      ),
    );
  }

  Widget _buildSyncProgress() {
    return Container(
      color: const Color(0xFF00ADB5).withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ADB5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              patchService.syncStatusText.isNotEmpty
                  ? patchService.syncStatusText
                  : 'Sincronizando con Boss GT-1B...',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF00ADB5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${(patchService.syncProgress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF00ADB5),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
