import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import '../widgets/stompbox_card.dart';
import '../widgets/tuner_modal.dart';

class HomePedalboardScreen extends StatelessWidget {
  const HomePedalboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiService>();
    final patchService = context.watch<PatchService>();
    final current = patchService.currentPatch;

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
          // Patch Selector Header
          _buildPatchHeader(context, patchService, current),

          // Pedalboard Effect Chain
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CADENA DE EFECTOS (GT-1B)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Toca para encender / apagar',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: current.effects.length,
                  itemBuilder: (context, index) {
                    final effect = current.effects[index];
                    return StompboxCard(
                      effect: effect,
                      onToggle: () => patchService.toggleEffect(effect),
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
          color: connected ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: connected ? Colors.green : Colors.red, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.usb : Icons.usb_off,
              size: 14,
              color: connected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              connected ? midi.connectedDeviceName : 'Desconectada',
              style: TextStyle(
                fontSize: 12,
                color: connected ? Colors.green : Colors.red,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      color: const Color(0xFF191921),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: patchService.currentPatchIndex > 0 ? () => patchService.previousPatch() : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  current.displayNumber,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00ADB5),
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  current.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
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
              title: const Text('Cable USB OTG'),
              subtitle: const Text('Conexión directa por cable'),
              onTap: () {
                Navigator.pop(ctx);
                midi.connect(type: ConnectionType.usbOtg);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
              title: const Text('Bluetooth Inalámbrico'),
              subtitle: const Text('Puente ESP32-S3 / HC-06'),
              onTap: () {
                Navigator.pop(ctx);
                midi.connect(type: ConnectionType.bluetoothBle);
              },
            ),
          ],
        ),
      ),
    );
  }
}
