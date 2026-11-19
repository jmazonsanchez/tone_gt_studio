import 'package:flutter/material.dart';
import '../../services/patch_service.dart';
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 520),
      decoration: BoxDecoration(
        color: const Color(0xFF13131C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00ADB5).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Modal Header
            _buildHeader(context),

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
                  Tab(icon: Icon(Icons.tune, size: 16), text: 'GLOBAL & SALIDA'),
                  Tab(icon: Icon(Icons.speed, size: 16), text: 'METRÓNOMO'),
                  Tab(icon: Icon(Icons.usb, size: 16), text: 'USB & HARDWARE'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: Color(0xFF00ADB5), size: 18),
              SizedBox(width: 8),
              Text(
                'SISTEMA Y UTILIDADES GT-1B',
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
}
