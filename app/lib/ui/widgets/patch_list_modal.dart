import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import 'patch_backup_tab.dart';
import 'patch_preset_tab.dart';
import 'patch_user_tab.dart';

/// Modal dialog for browsing, selecting, backing up, and writing GT-1B Presets (Phase 7)
class PatchListModal extends StatelessWidget {
  const PatchListModal({super.key});

  @override
  Widget build(BuildContext context) {
    final patchService = context.watch<PatchService>();
    final midiService = context.watch<MidiService>();
    final isSyncing = patchService.isSyncing;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Modal Header
            _buildHeader(context),

            // Hardware Sync Progress Banner
            _buildSyncBanner(patchService, midiService, isSyncing),

            // Tab Navigation Bar
            Container(
              color: const Color(0xFF181824),
              child: const TabBar(
                indicatorColor: Color(0xFF00ADB5),
                indicatorWeight: 3,
                labelColor: Color(0xFF00ADB5),
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                tabs: [
                  Tab(icon: Icon(Icons.person, size: 16), text: 'USER (U01-U99)'),
                  Tab(icon: Icon(Icons.lock, size: 16), text: 'FÁBRICA (P01-P99)'),
                  Tab(icon: Icon(Icons.cloud_sync, size: 16), text: 'BACKUP & TSL'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  PatchUserTab(
                    patchService: patchService,
                    onPatchSelected: () => Navigator.pop(context),
                  ),
                  PatchPresetTab(
                    patchService: patchService,
                    onPatchSelected: () => Navigator.pop(context),
                  ),
                  PatchBackupTab(patchService: patchService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.library_music, color: Color(0xFF00ADB5), size: 18),
              SizedBox(width: 8),
              Text(
                'BIBLIOTECA DE PRESETS GT-1B (198 BANCOS)',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner(PatchService patchService, MidiService midiService, bool isSyncing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF161622),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isSyncing ? Icons.sync : Icons.download_for_offline,
                color: const Color(0xFF00ADB5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSyncing
                      ? patchService.syncStatusText
                      : (midiService.isConnected
                          ? 'Sincronizar nombres reales de la pedalera'
                          : 'Modo Offline (Conecta por USB para leer tu pedal)'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSyncing ? const Color(0xFF00ADB5) : Colors.white60,
                    fontWeight: isSyncing ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: (!midiService.isConnected || isSyncing)
                    ? null
                    : () => patchService.syncAllPatchesFromPedal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ADB5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isSyncing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('LEER TODO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          if (isSyncing) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: patchService.syncProgress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00ADB5)),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
