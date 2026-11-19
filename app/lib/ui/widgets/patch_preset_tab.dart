import 'package:flutter/material.dart';
import '../../models/patch.dart';
import '../../services/patch_service.dart';
import 'patch_write_modal.dart';

/// Factory Presets Tab (P01..P99) - Read-only presets with Clone to User support
class PatchPresetTab extends StatefulWidget {
  final PatchService patchService;
  final VoidCallback onPatchSelected;

  const PatchPresetTab({
    super.key,
    required this.patchService,
    required this.onPatchSelected,
  });

  @override
  State<PatchPresetTab> createState() => _PatchPresetTabState();
}

class _PatchPresetTabState extends State<PatchPresetTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final presetPatches = widget.patchService.patches.sublist(99);
    final filtered = presetPatches.where((p) {
      final q = _search.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.displayNumber.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Notice Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock, size: 14, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Los presets P01-P99 son de solo lectura de fábrica. Para editarlos, pulsa "Copiar a User".',
                  style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar en presets de Fábrica (P01-P99)...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1B1B26),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),

        // List of factory preset patches
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, idx) {
              final patch = filtered[idx];
              final isCurrent = patch.index == widget.patchService.currentPatchIndex;

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: Text(
                    patch.displayNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isCurrent ? Colors.amber : Colors.white54,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          patch.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: const Text('FÁBRICA', style: TextStyle(fontSize: 8, color: Colors.amber, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00ADB5), width: 0.8),
                          foregroundColor: const Color(0xFF00ADB5),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          widget.patchService.selectPatch(patch.index);
                          PatchWriteModal.show(context, widget.patchService);
                        },
                        icon: const Icon(Icons.copy, size: 12),
                        label: const Text('COPIAR A USER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrent)
                        const Icon(Icons.check_circle, color: Colors.amber, size: 18)
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF222232),
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _selectPatch(patch),
                          child: const Text('ESCUCHAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  tileColor: isCurrent ? Colors.amber.withValues(alpha: 0.1) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => _selectPatch(patch),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _selectPatch(Patch patch) {
    widget.patchService.selectPatch(patch.index);
    widget.onPatchSelected();
  }
}
