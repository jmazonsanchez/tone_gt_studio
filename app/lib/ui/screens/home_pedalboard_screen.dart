import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import '../widgets/mini_pedal_card.dart';
import '../widgets/effect_detail_modal.dart';
import '../widgets/patch_list_modal.dart';
import '../widgets/tuner_modal.dart';

class HomePedalboardScreen extends StatelessWidget {
  const HomePedalboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiService>();
    final patchService = context.watch<PatchService>();
    final current = patchService.currentPatch;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive columns for mini-pedalboard
    final int crossAxisCount = screenWidth > 950 ? 4 : (screenWidth > 550 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.graphic_eq, color: Color(0xFF00ADB5)),
            const SizedBox(width: 8),
            const Text(
              'tone_gt_studio',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
            const Spacer(),
            _buildConnectionBadge(context, midi),
          ],
        ),
      ),
      body: Column(
        children: [
          // Patch Selector Header (Tap center to open full 99 patches list)
          _buildPatchHeader(context, patchService, current),

          // Real-time Sync Progress Banner (when reading from GT-1B)
          if (patchService.isSyncing)
            Container(
              color: const Color(0xFF00ADB5).withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00ADB5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patchService.syncStatusText,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF00ADB5), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Pedalboard Effect Chain
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.developer_board, size: 16, color: Color(0xFF00ADB5)),
                        SizedBox(width: 6),
                        Text(
                          'PEDALBOARD BOUTIQUE (GT-1B)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => const PatchListModal(),
                        );
                      },
                      icon: const Icon(Icons.sync, size: 14, color: Color(0xFF00ADB5)),
                      label: const Text(
                        'Leer Presets',
                        style: TextStyle(fontSize: 11, color: Color(0xFF00ADB5), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.70, // Authentic boutique mini-pedal ratio
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: current.effects.length,
                  itemBuilder: (context, index) {
                    final effect = current.effects[index];
                    return MiniPedalCard(
                      effect: effect,
                      onToggle: () => patchService.toggleEffect(effect),
                      onOpenDetail: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => EffectDetailModal(effect: effect),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(context, patchService),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(BuildContext context, MidiService midi) {
    final connected = midi.isConnected;
    final isConnecting = midi.connectionState == MidiConnectionState.connecting;

    Color badgeColor = Colors.red;
    String badgeText = 'Desconectada';
    IconData badgeIcon = Icons.usb_off;

    if (connected) {
      badgeColor = Colors.green;
      badgeText = midi.connectedDeviceName;
      badgeIcon = Icons.usb;
    } else if (isConnecting) {
      badgeColor = Colors.amber;
      badgeText = 'Conectando...';
      badgeIcon = Icons.sync;
    }

    return GestureDetector(
      onTap: () {
        if (connected) {
          midi.disconnect();
        } else {
          _showConnectionDialog(context, midi);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badgeColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isConnecting
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                : Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatchHeader(BuildContext context, PatchService patchService, dynamic current) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFF191921),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: patchService.currentPatchIndex > 0 ? () => patchService.previousPatch() : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const PatchListModal(),
                );
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          current.displayNumber,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00ADB5),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF00ADB5), size: 24),
                      ],
                    ),
                    Text(
                      current.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: patchService.currentPatchIndex < 98 ? () => patchService.nextPatch() : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, PatchService patchService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF14141A),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                patchService.toggleTuner();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => TunerModal(
                    onClose: () {
                      patchService.toggleTuner();
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.tune),
              label: const Text('AFINADOR / MUTE', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, MidiService midi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C24),
        title: const Text('Conectar con GT-1B'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.usb, color: Color(0xFF00ADB5)),
              title: const Text('Cable USB (OTG / Directo)'),
              subtitle: const Text('Conexión directa USB MIDI (SysEx)'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await midi.connect(type: ConnectionType.usbOtg);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '✅ Conectado exitosamente con ${midi.connectedDeviceName}'
                          : '⚠️ No se pudo conectar con la Boss GT-1B. Verifica el cable USB y permisos MIDI.'),
                      backgroundColor: ok ? Colors.teal : Colors.deepOrange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
              title: const Text('Bluetooth Inalámbrico'),
              subtitle: const Text('Puente ESP32-S3 / HC-06'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await midi.connect(type: ConnectionType.bluetoothBle);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '✅ Conectado vía Bluetooth: ${midi.connectedDeviceName}'
                          : '⚠️ No se detectó puente Bluetooth BLE activo.'),
                      backgroundColor: ok ? Colors.teal : Colors.deepOrange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
