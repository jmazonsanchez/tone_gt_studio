import 'package:flutter/material.dart';
import '../../services/patch_service.dart';

/// Modal dialog to save/commit the active temporary patch into GT-1B permanent user flash memory (U01..U99).
class PatchWriteModal extends StatefulWidget {
  final PatchService patchService;
  final int? initialTargetIndex;

  const PatchWriteModal({
    super.key,
    required this.patchService,
    this.initialTargetIndex,
  });

  static Future<void> show(BuildContext context, PatchService patchService, {int? targetIndex}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: PatchWriteModal(
          patchService: patchService,
          initialTargetIndex: targetIndex,
        ),
      ),
    );
  }

  @override
  State<PatchWriteModal> createState() => _PatchWriteModalState();
}

class _PatchWriteModalState extends State<PatchWriteModal> {
  late int _selectedTarget;
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentIdx = widget.patchService.currentPatchIndex;
    _selectedTarget = widget.initialTargetIndex ?? (currentIdx < 99 ? currentIdx : 0);
    _nameController = TextEditingController(text: widget.patchService.currentPatch.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userPatches = widget.patchService.patches.sublist(0, 99);
    final targetPatch = userPatches[_selectedTarget];

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00ADB5).withValues(alpha: 0.4), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 24, spreadRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.save, color: Color(0xFF00ADB5), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GUARDAR PRESET EN GT-1B',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Patch Name TextField
          const Text('NOMBRE DEL PRESET (MÁX. 16 CARACTERES)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            maxLength: 16,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1B1B26),
              counterStyle: const TextStyle(color: Colors.white30, fontSize: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Target User Slot Selector
          const Text('DESTINO EN MEMORIA DE USUARIO (U01-U99)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedTarget,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B1B26),
                style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 13),
                items: List.generate(userPatches.length, (idx) {
                  final p = userPatches[idx];
                  return DropdownMenuItem(
                    value: idx,
                    child: Text('${p.displayNumber}: ${p.name}'),
                  );
                }),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTarget = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Warning Notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se sobrescribirá el contenido de ${targetPatch.displayNumber} (${targetPatch.name}) en la memoria de la pedalera.',
                    style: const TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR EN HARDWARE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ADB5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await widget.patchService.writeCurrentPatchToHardware(
      _selectedTarget,
      newName: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Preset guardado en U${(_selectedTarget + 1).toString().padLeft(2, "0")}!'),
          backgroundColor: const Color(0xFF00ADB5),
        ),
      );
    }
  }
}
