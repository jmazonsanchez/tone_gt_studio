import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_config.dart';
import '../../services/patch_service.dart';
import '../../services/storage/app_database.dart';
import '../../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Modal tab for inspecting and managing the internal persistent database,
/// per-device configurations, live performance shortcuts, and theme storage.
class SystemDatabaseTab extends StatelessWidget {
  final PatchService patchService;

  const SystemDatabaseTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    AppDatabase? db;
    try {
      db = context.watch<AppDatabase>();
    } catch (_) {
      db = AppDatabase.instance;
    }

    final themeService = Provider.of<ThemeService?>(context, listen: false);
    final activeDeviceId = db.getActiveDeviceId();
    final config = db.getDeviceConfig(activeDeviceId);
    final quickPresets = db.getQuickPresets(activeDeviceId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDatabaseHeaderCard(colors, config, db),
          const SizedBox(height: 14),
          _buildDeviceSettingsCard(context, colors, config, themeService),
          const SizedBox(height: 14),
          _buildLiveShortcutsCard(context, colors, quickPresets),
          const SizedBox(height: 14),
          _buildActionButtons(context, colors, db, activeDeviceId),
        ],
      ),
    );
  }

  Widget _buildDatabaseHeaderCard(AppColorScheme colors, DeviceConfig config, AppDatabase db) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storage_rounded, size: 28, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BASE DE DATOS INTERNA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTIVA Y PERSISTENTE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Almacena configuraciones por dispositivo, accesos directos para el en vivo y modo visual sin conexión.',
                  style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSettingsCard(
    BuildContext context,
    AppColorScheme colors,
    DeviceConfig config,
    ThemeService? themeService,
  ) {
    final modeLabel = themeService?.isLightMode == true ? 'Modo Claro' : 'Modo Oscuro';
    final connLabel = config.lastConnectionType == 'bluetoothBle' ? 'Bluetooth BLE' : 'Cable USB OTG';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'PERFIL GUARDADO: ${config.deviceName.toUpperCase()}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('ID del Dispositivo', config.deviceId, colors),
          _buildInfoRow('Última Conexión Utilizada', connLabel, colors),
          _buildInfoRow('Reconexión Automática', config.autoReconnect ? 'Habilitada' : 'Deshabilitada', colors),
          _buildInfoRow('Tema Visual Persistido', modeLabel, colors),
          _buildInfoRow('Metrónomo Guardado', '${config.metronomeBpm} BPM (${config.metronomeTimeSignature}/4)', colors),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: colors.textMuted)),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveShortcutsCard(BuildContext context, AppColorScheme colors, List dynamicPresets) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFFF9800)),
                  const SizedBox(width: 8),
                  Text(
                    'ACCESOS DIRECTOS EN VIVO (${dynamicPresets.length})',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EN VIVO',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF9800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (dynamicPresets.isEmpty)
            Text(
              'No hay accesos directos configurados para este dispositivo.',
              style: TextStyle(fontSize: 11, color: colors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: dynamicPresets.map((qp) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(qp.colorValue).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(qp.colorValue).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(qp.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        qp.customLabel.isNotEmpty ? qp.customLabel : 'P${qp.patchIndex + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppColorScheme colors,
    AppDatabase db,
    String activeDeviceId,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await db.resetDeviceConfig(activeDeviceId);
              patchService.setInitialSyncComplete(patchService.isInitialSyncComplete);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración del dispositivo restablecida a valores por defecto.'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'RESTABLECER DISPOSITIVO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
