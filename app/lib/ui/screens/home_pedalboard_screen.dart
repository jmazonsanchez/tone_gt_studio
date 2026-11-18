import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import 'gateway_screen.dart';
import 'stage_pedalboard_screen.dart';

class HomePedalboardScreen extends StatefulWidget {
  const HomePedalboardScreen({super.key});

  @override
  State<HomePedalboardScreen> createState() => _HomePedalboardScreenState();
}

class _HomePedalboardScreenState extends State<HomePedalboardScreen> {
  bool _isDemoMode = false;

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiService>();
    final patchService = context.watch<PatchService>();
    final isUnlocked = midi.isConnected || _isDemoMode;

    if (!isUnlocked) {
      return GatewayScreen(
        midi: midi,
        onEnterDemoMode: () {
          setState(() {
            _isDemoMode = true;
          });
        },
      );
    }

    return StagePedalboardScreen(
      midi: midi,
      patchService: patchService,
      isDemoMode: _isDemoMode,
      onExitDemo: () {
        setState(() {
          _isDemoMode = false;
        });
      },
      onConnectRequest: () => _showConnectionDialog(context, midi),
    );
  }

  void _showConnectionDialog(BuildContext context, MidiService midi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Conectar con Boss GT-1B', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.usb, color: Color(0xFF00ADB5), size: 28),
              title: const Text('Cable USB OTG', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Conexión física directa recomendada'),
              onTap: () async {
                Navigator.pop(ctx);
                await midi.connect(type: ConnectionType.usbOtg);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.bluetooth, color: Colors.blueAccent, size: 28),
              title: const Text('Bluetooth BLE', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Puente inalámbrico ESP32 MIDI'),
              onTap: () async {
                Navigator.pop(ctx);
                await midi.connect(type: ConnectionType.bluetoothBle);
              },
            ),
          ],
        ),
      ),
    );
  }
}
