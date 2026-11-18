import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/patch_service.dart';

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
    final allPatches = patchService.patches;
    final filtered = allPatches.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.displayNumber.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
              const Text(
                'LIBRERÍA DE PATCHES (U01 - U99)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
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
          const SizedBox(height: 16),
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
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF00ADB5), size: 20)
                      : null,
                  tileColor: isSelected ? const Color(0xFF00ADB5).withOpacity(0.12) : null,
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
