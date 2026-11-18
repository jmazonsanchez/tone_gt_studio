import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/patch_service.dart';
import '../../services/midi_service.dart';

class PatchListModal extends StatefulWidget {
  const PatchListModal({super.key});

  @override
  State<PatchListModal> createState() => _PatchListModalState();
}

class _PatchListModalState extends State<PatchListModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final patchService = context.watch<PatchService>();
    final midiService = context.watch<MidiService>();
    final allPatches = patchService.patches;
    final isSyncing = patchService.isSyncing;

    final filtered = allPatches.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.displayNumber.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF14141A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.library_music, color: Color(0xFF00ADB5), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PRESETS GT-1B (U01-U99 / P01-P99)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hardware Sync Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSyncing ? const Color(0xFF00ADB5) : Colors.white12,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isSyncing ? Icons.sync : Icons.download_for_offline,
                      color: const Color(0xFF00ADB5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSyncing ? 'Sincronizando con pedalera...' : 'Sincronizar Presets de GT-1B',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            isSyncing
                                ? patchService.syncStatusText
                                : (midiService.isConnected
                                    ? 'Lee tus 99 bancos reales configurados en tu pedal'
                                    : 'Conecta tu pedalera para sincronizar bancos'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSyncing ? const Color(0xFF00ADB5) : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (!midiService.isConnected || isSyncing)
                          ? null
                          : () => patchService.syncAllPatchesFromPedal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00ADB5),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Leer Preset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                if (isSyncing) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: patchService.syncProgress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00ADB5)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search box
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Buscar patch por nombre o número...',
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1C1C24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Patches List
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final p = filtered[index];
                final isSelected = p.index == patchService.currentPatchIndex;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Text(
                    p.displayNumber,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF00ADB5) : Colors.white54,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      if (p.isReadOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: const Text(
                            'SOLO LECTURA',
                            style: TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF00ADB5), size: 20)
                      : null,
                  tileColor: isSelected ? const Color(0xFF00ADB5).withValues(alpha: 0.12) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    patchService.selectPatch(p.index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
