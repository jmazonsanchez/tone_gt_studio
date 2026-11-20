import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/midi_service.dart';
import '../../services/patch_service.dart';
import 'disconnected_screen.dart';
import 'gateway_screen.dart';
import 'stage_pedalboard_screen.dart';
import 'sync_loading_screen.dart';

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

    if (midi.isConnected && _isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isDemoMode = false);
      });
    }

    final isUnlocked = midi.isConnected || _isDemoMode;

    if (!isUnlocked) {
      if (midi.hasHadActiveConnection) {
        return DisconnectedScreen(
          midi: midi,
          onEnterDemoMode: () {
            setState(() {
              _isDemoMode = true;
            });
          },
        );
      }

      return GatewayScreen(
        midi: midi,
        onEnterDemoMode: () {
          setState(() {
            _isDemoMode = true;
          });
        },
      );
    }

    // Pantalla de carga / sincronización bloqueante mientras se lee la pedalera por OTG o Bluetooth
    if (midi.isConnected && !patchService.isInitialSyncComplete && !_isDemoMode) {
      return SyncLoadingScreen(
        midi: midi,
        patchService: patchService,
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
                final ok = await midi.connect(type: ConnectionType.usbOtg);
                if (!ok && context.mounted) {
                  _showNotConnectedSnackBar(context, 'cable USB OTG');
                }
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
                final ok = await midi.connect(type: ConnectionType.bluetoothBle);
                if (!ok && context.mounted) {
                  _showNotConnectedSnackBar(context, 'Bluetooth BLE');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotConnectedSnackBar(BuildContext context, String typeLabel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No estás conectado a ningún dispositivo MIDI. Conecta tu Boss GT-1B por $typeLabel y vuelve a intentarlo.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
