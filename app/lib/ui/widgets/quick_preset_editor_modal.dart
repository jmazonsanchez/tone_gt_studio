import 'package:flutter/material.dart';
import '../../models/quick_preset.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Modal dialog for adding, editing, and removing live preset shortcuts.
class QuickPresetEditorModal extends StatefulWidget {
  final PatchService patchService;
  final QuickPreset? existing;

  const QuickPresetEditorModal({super.key, required this.patchService, this.existing});

  static Future<void> show(BuildContext context, PatchService patchService, {QuickPreset? existing}) {
    return showDialog(
      context: context,
      builder: (ctx) => QuickPresetEditorModal(patchService: patchService, existing: existing),
    );
  }

  @override
  State<QuickPresetEditorModal> createState() => _QuickPresetEditorModalState();
}

class _QuickPresetEditorModalState extends State<QuickPresetEditorModal> {
  late int _selectedPatchIndex;
  late TextEditingController _labelController;
  late int _selectedColor;

  static const List<int> _colors = [
    0xFF00ADB5, // Cyan GT
    0xFFFF9800, // Naranja
    0xFF9C27B0, // Púrpura
    0xFFE53935, // Rojo
    0xFF4CAF50, // Verde
    0xFF2196F3, // Azul
    0xFFFFC107, // Oro
  ];

  @override
  void initState() {
    super.initState();
    final pService = widget.patchService;
    _selectedPatchIndex = widget.existing?.patchIndex ?? pService.currentPatchIndex;
    final initialLabel = widget.existing?.customLabel ??
        (pService.patches.isNotEmpty && _selectedPatchIndex < pService.patches.length
            ? pService.patches[_selectedPatchIndex].name
            : '');
    _labelController = TextEditingController(text: initialLabel);
    _selectedColor = widget.existing?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final patches = widget.patchService.patches;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.borderSubtle)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colors),
              const SizedBox(height: 16),
              _buildPresetDropdown(patches, colors),
              const SizedBox(height: 14),
              _buildLabelField(colors),
              const SizedBox(height: 14),
              _buildColorPicker(colors),
              const SizedBox(height: 20),
              _buildActionButtons(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: Color(_selectedColor), size: 22),
            const SizedBox(width: 8),
            Text(
              _isEditing ? 'EDITAR ACCESO DIRECTO' : 'NUEVO ACCESO DIRECTO',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8, color: colors.textPrimary),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.close, size: 20, color: colors.textMuted),
          onPressed: () => Navigator.of(context).pop(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildPresetDropdown(List<dynamic> patches, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PRESET ASOCIADO:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedPatchIndex.clamp(0, patches.isNotEmpty ? patches.length - 1 : 0),
              isExpanded: true,
              dropdownColor: colors.surfaceVariant,
              items: patches.map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                value: p.index as int,
                child: Text('[${p.displayNumber}] ${p.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPatchIndex = val;
                    if (_labelController.text.isEmpty && val < patches.length) {
                      _labelController.text = patches[val].name;
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelField(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ETIQUETA EN VIVO (CANCIÓN / SECCIÓN):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _labelController,
          style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Ej. Intro Slap, Solo Fuzz, Canción 2...',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
            filled: true,
            fillColor: colors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderSubtle)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(_selectedColor), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COLOR EN ESCENARIO:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _colors.map((c) {
            final sel = c == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? Colors.white : Colors.transparent, width: sel ? 2.5 : 1),
                  boxShadow: sel ? [BoxShadow(color: Color(c).withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)] : null,
                ),
                child: sel ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColorScheme colors) {
    return Row(
      children: [
        if (_isEditing)
          TextButton.icon(
            key: const Key('delete-quick-preset-btn'),
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            label: const Text('QUITAR', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              widget.patchService.removeQuickPreset(widget.existing!.id);
              Navigator.of(context).pop();
            },
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCELAR', style: TextStyle(color: colors.textMuted, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          key: const Key('save-quick-preset-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(_selectedColor),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _savePreset,
          child: Text(_isEditing ? 'GUARDAR' : 'AGREGAR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  void _savePreset() {
    final label = _labelController.text.trim();
    if (_isEditing) {
      widget.patchService.updateQuickPreset(
        widget.existing!.id,
        patchIndex: _selectedPatchIndex,
        customLabel: label,
        colorValue: _selectedColor,
      );
    } else {
      widget.patchService.addQuickPreset(
        patchIndex: _selectedPatchIndex,
        customLabel: label,
        colorValue: _selectedColor,
      );
    }
    Navigator.of(context).pop();
  }
}
