import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';
import 'system_appearance_tab.dart';
import 'system_database_tab.dart';
import 'system_global_tab.dart';
import 'system_metronome_tab.dart';
import 'system_usb_tab.dart';

/// Modal dialog for Boss GT-1B System & Global Settings (Phase 6)
class SystemSettingsModal extends StatelessWidget {
  final PatchService patchService;

  const SystemSettingsModal({super.key, required this.patchService});

  static Future<void> show(BuildContext context, PatchService patchService) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: AnimatedBuilder(
          animation: patchService,
          builder: (context, _) => SystemSettingsModal(patchService: patchService),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 520),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.7 : 0.15),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            // Modal Header
            _buildHeader(context, colors),

            // Tab Navigation Bar
            Container(
              color: colors.surfaceVariant,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: colors.primary,
                indicatorWeight: 3,
                labelColor: colors.primary,
                unselectedLabelColor: colors.textMuted,
                labelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                tabs: const [
                  Tab(icon: Icon(Icons.tune, size: 16), text: 'GLOBAL & SALIDA'),
                  Tab(icon: Icon(Icons.speed, size: 16), text: 'METRÓNOMO'),
                  Tab(icon: Icon(Icons.usb, size: 16), text: 'USB & HARDWARE'),
                  Tab(icon: Icon(Icons.palette_outlined, size: 16), text: 'APARIENCIA'),
                  Tab(icon: Icon(Icons.storage_rounded, size: 16), text: 'BASE & PERFILES'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  SystemGlobalTab(patchService: patchService),
                  SystemMetronomeTab(patchService: patchService),
                  SystemUsbTab(patchService: patchService),
                  const SystemAppearanceTab(),
                  SystemDatabaseTab(patchService: patchService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'SISTEMA Y UTILIDADES GT-1B',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textMuted, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
