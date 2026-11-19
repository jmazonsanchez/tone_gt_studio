import 'package:flutter/material.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import 'assign_editor_modal.dart';
import 'patch_list_modal.dart';
import 'patch_write_modal.dart';
import 'system_settings_modal.dart';
import 'tuner_modal.dart';

class StageHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final MidiService midi;
  final PatchService patchService;
  final bool isDemoMode;
  final VoidCallback onExitDemo;
  final VoidCallback onConnectRequest;

  const StageHeaderBar({
    super.key,
    required this.midi,
    required this.patchService,
    required this.isDemoMode,
    required this.onExitDemo,
    required this.onConnectRequest,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final current = patchService.currentPatch;
    final isConnected = midi.isConnected;
    final isConnecting = midi.connectionState == MidiConnectionState.connecting;
    final isReconnecting = midi.connectionState == MidiConnectionState.reconnecting;
    final isReadOnly = current.isReadOnly;

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          // 1. Connection Status Badge
          _buildConnectionStatus(context, isConnected, isConnecting, isReconnecting),

          const SizedBox(width: 8),

          // 2. Demo Mode indicator if active
          if (isDemoMode && !isConnected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.purpleAccent, width: 0.8)),
              child: InkWell(
                onTap: onExitDemo,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.exit_to_app, size: 12, color: Colors.purpleAccent),
                    SizedBox(width: 4),
                    Text('SALIR DEMO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 3. Central Patch Selector (Large Stage Display)
          Expanded(child: _buildPatchSelector(context, current, isReadOnly)),
          const SizedBox(width: 8),

          // 4. Quick Hardware Write / Save Button
          _buildWriteButton(context),
          const SizedBox(width: 8),

          // 5. Tuner / Mute Button
          _buildTunerButton(context),
          const SizedBox(width: 8),

          // 6. Phase 5: CTL1 / EXP / Assigns Button
          _buildAssignsButton(context),
          const SizedBox(width: 8),

          // 7. Phase 6: System & Utilities Button
          _buildSystemButton(context),
          const SizedBox(width: 8),

          // 8. Library / Presets Button
          _buildLibraryButton(context),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, bool isConnected, bool isConnecting, bool isReconnecting) {
    Color color = Colors.redAccent;
    String label = 'DESCONECTADO';
    IconData icon = Icons.usb_off;

    if (isConnected) {
      color = const Color(0xFF00ADB5);
      label = 'GT-1B EN VIVO';
      icon = Icons.usb;
    } else if (isConnecting) {
      color = Colors.amber;
      label = 'CONECTANDO...';
      icon = Icons.sync;
    } else if (isReconnecting) {
      color = Colors.orangeAccent;
      label = 'RECONECTANDO...';
      icon = Icons.sync_problem;
    } else if (isDemoMode) {
      color = Colors.purpleAccent;
      label = 'MODO DEMO';
      icon = Icons.bolt;
    }

    return InkWell(
      onTap: isConnected ? () => midi.disconnect() : onConnectRequest,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1.2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnecting || isReconnecting)
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatchSelector(BuildContext context, dynamic current, bool isReadOnly) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('prev-patch-btn'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 24),
            onPressed: patchService.currentPatchIndex > 0 ? () => patchService.previousPatch() : null,
          ),
          Expanded(
            child: InkWell(
              onTap: () => _openPatchList(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    current.displayNumber,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isReadOnly ? Colors.amber : const Color(0xFF00ADB5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (isReadOnly) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber, width: 0.8),
                      ),
                      child: const Text('FABRICA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      current.name.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 20),
                ],
              ),
            ),
          ),
          IconButton(
            key: const Key('next-patch-btn'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
            onPressed: patchService.currentPatchIndex < (patchService.patches.length - 1) ? () => patchService.nextPatch() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWriteButton(BuildContext context) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF222230), side: const BorderSide(color: Colors.white12, width: 1)),
      onPressed: () => PatchWriteModal.show(context, patchService),
      icon: const Icon(Icons.save, size: 18, color: Color(0xFFFF9800)),
      tooltip: 'Guardar Preset en Pedalera (Write)',
    );
  }

  Widget _buildTunerButton(BuildContext context) {
    final active = patchService.isTunerActive;
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: active ? const Color(0xFF00ADB5).withValues(alpha: 0.25) : const Color(0xFF222230),
        side: BorderSide(color: active ? const Color(0xFF00ADB5) : Colors.white12, width: 1),
      ),
      onPressed: () {
        patchService.toggleTuner();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => TunerModal(
            patchService: patchService,
            onClose: () {
              patchService.toggleTuner();
              Navigator.pop(ctx);
            },
          ),
        );
      },
      icon: Icon(Icons.tune, size: 18, color: active ? const Color(0xFF00ADB5) : Colors.white70),
      tooltip: 'Afinador / Silenciador',
    );
  }

  Widget _buildAssignsButton(BuildContext context) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF222230), side: const BorderSide(color: Colors.white12, width: 1)),
      onPressed: () => AssignEditorModal.show(context, patchService),
      icon: const Icon(Icons.settings_remote, size: 18, color: Color(0xFF00ADB5)),
      tooltip: 'CTL1 / EXP / Assigns 1-8',
    );
  }

  Widget _buildSystemButton(BuildContext context) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF222230), side: const BorderSide(color: Colors.white12, width: 1)),
      onPressed: () => SystemSettingsModal.show(context, patchService),
      icon: const Icon(Icons.settings, size: 18, color: Color(0xFF00ADB5)),
      tooltip: 'Sistema y Utilidades GT-1B (Fase 6)',
    );
  }

  Widget _buildLibraryButton(BuildContext context) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: const Color(0xFF222230), side: const BorderSide(color: Colors.white12, width: 1)),
      onPressed: () => _openPatchList(context),
      icon: const Icon(Icons.library_music, size: 18, color: Colors.white70),
      tooltip: 'Lista de 198 Presets (U y P)',
    );
  }

  void _openPatchList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PatchListModal(),
    );
  }
}
