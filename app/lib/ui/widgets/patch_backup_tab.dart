import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/tsl_serializer.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// Backup & Tone Studio (.tsl) LiveSet Import/Export Tab
class PatchBackupTab extends StatefulWidget {
  final PatchService patchService;

  const PatchBackupTab({super.key, required this.patchService});

  @override
  State<PatchBackupTab> createState() => _PatchBackupTabState();
}

class _PatchBackupTabState extends State<PatchBackupTab> {
  final TextEditingController _importController = TextEditingController();
  String _statusMessage = '';

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExportCard(colors),
          const SizedBox(height: 14),
          _buildActivePatchCard(colors),
          const SizedBox(height: 14),
          _buildImportCard(colors),

          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primary),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportCard(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_zip, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'EXPORTAR LIVESET BOSS TONE STUDIO (.TSL)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Genera un archivo .tsl compatible con Boss Tone Studio conteniendo los 99 presets de Usuario.',
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _exportLiveSet,
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('COPIAR LIVESET (.TSL) AL PORTAPAPELES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePatchCard(AppColorScheme colors) {
    final current = widget.patchService.currentPatch;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: colors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'EXPORTAR PRESET ACTIVO: ${current.displayNumber} (${current.name})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Exporta la configuración completa de potenciómetros, ruteo y switches de este preset en JSON.',
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.isDark ? const Color(0xFF252538) : colors.surfaceVariant,
              foregroundColor: colors.accent,
              side: BorderSide(color: colors.accent, width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _exportSinglePatch,
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('COPIAR PRESET JSON AL PORTAPAPELES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'IMPORTAR PRESET O LIVESET (.TSL / JSON)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _importController,
            maxLines: 4,
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Pega aquí el contenido JSON del archivo .tsl o del preset exportado...',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 11),
              filled: true,
              fillColor: colors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _importContent,
            icon: const Icon(Icons.check, size: 14),
            label: const Text('PROCESAR E IMPORTAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportLiveSet() {
    final userPatches = widget.patchService.patches.sublist(0, 99);
    final jsonText = TslSerializer.exportLiveSet(
      liveSetName: 'Copia GT-1B Backup',
      patches: userPatches,
    );
    Clipboard.setData(ClipboardData(text: jsonText));
    setState(() => _statusMessage = '¡LiveSet copiado al portapapeles! Puedes guardarlo en un archivo .tsl.');
  }

  void _exportSinglePatch() {
    final current = widget.patchService.currentPatch;
    final jsonText = TslSerializer.exportSinglePatch(current);
    Clipboard.setData(ClipboardData(text: jsonText));
    setState(() => _statusMessage = '¡Preset "${current.name}" copiado al portapapeles como JSON!');
  }

  void _importContent() {
    final text = _importController.text.trim();
    if (text.isEmpty) return;

    try {
      if (text.contains('"liveSetData"')) {
        final imported = TslSerializer.importLiveSet(
          text,
          templatePatches: widget.patchService.patches.sublist(0, 99),
        );
        setState(() => _statusMessage = '¡LiveSet importado correctamente! (${imported.length} presets leídos).');
      } else {
        final current = widget.patchService.currentPatch;
        final updated = TslSerializer.importSinglePatch(text, current);
        widget.patchService.renameCurrentPatch(updated.name);
        setState(() => _statusMessage = '¡Preset "${updated.name}" importado en el slot activo!');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error al importar: $e');
    }
  }
}
