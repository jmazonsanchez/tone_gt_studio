import 'package:flutter/material.dart';
import '../../models/patch.dart';
import '../../services/patch_service.dart';
import 'patch_write_modal.dart';

/// User Presets Tab (U01..U99) with full editing, selection and write support
class PatchUserTab extends StatefulWidget {
  final PatchService patchService;
  final VoidCallback onPatchSelected;

  const PatchUserTab({
    super.key,
    required this.patchService,
    required this.onPatchSelected,
  });

  @override
  State<PatchUserTab> createState() => _PatchUserTabState();
}

class _PatchUserTabState extends State<PatchUserTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final userPatches = widget.patchService.patches.sublist(0, 99);
    final filtered = userPatches.where((p) {
      final q = _search.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.displayNumber.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar en presets de Usuario (U01-U99)...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1B1B26),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),

        // List of user patches
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
                      color: isCurrent ? const Color(0xFF00ADB5) : Colors.white54,
                    ),
                  ),
                  title: Text(
                    patch.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : Colors.white70,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.save_as, size: 16, color: Color(0xFF00ADB5)),
                        tooltip: 'Sobrescribir este slot (Guardar)',
                        onPressed: () => PatchWriteModal.show(context, widget.patchService, targetIndex: patch.index),
                      ),
                      if (isCurrent)
                        const Icon(Icons.check_circle, color: Color(0xFF00ADB5), size: 18)
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
                          child: const Text('CARGAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  tileColor: isCurrent ? const Color(0xFF00ADB5).withValues(alpha: 0.12) : null,
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
