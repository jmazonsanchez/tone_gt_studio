import 'package:flutter/material.dart';
import '../../services/midi_service.dart';

/// Screen displayed when the USB or Bluetooth connection to the Boss GT-1B is lost.
/// Blocks interaction with the pedalboard until connection is re-established.
class DisconnectedScreen extends StatelessWidget {
  final MidiService midi;
  final VoidCallback onEnterDemoMode;

  const DisconnectedScreen({
    super.key,
    required this.midi,
    required this.onEnterDemoMode,
  });

  @override
  Widget build(BuildContext context) {
    final isConnecting = midi.connectionState == MidiConnectionState.connecting;
    final size = MediaQuery.of(context).size;
    final isHorizontal = size.width > size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: isHorizontal
                  ? _buildHorizontalLayout(context, isConnecting)
                  : _buildVerticalLayout(context, isConnecting),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, bool isConnecting) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAlertIcon(),
              const SizedBox(height: 18),
              _buildAlertBadge(),
              const SizedBox(height: 12),
              const Text(
                'Pedalera Desconectada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Se ha perdido la comunicación con la Boss GT-1B.\nLa edición en vivo está bloqueada para proteger la integridad de tus tonos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 5,
          child: _buildActionCard(context, isConnecting),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(BuildContext context, bool isConnecting) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAlertIcon(),
        const SizedBox(height: 16),
        _buildAlertBadge(),
        const SizedBox(height: 10),
        const Text(
          'Pedalera Desconectada',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Se ha perdido la comunicación con la Boss GT-1B.\nLa edición en vivo está bloqueada hasta que vuelvas a conectar el pedal.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        _buildActionCard(context, isConnecting),
      ],
    );
  }

  Widget _buildAlertIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1418),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.usb_off_rounded, size: 50, color: Color(0xFFFF5252)),
    );
  }

  Widget _buildAlertBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFF5252)),
          SizedBox(width: 6),
          Text(
            'COMUNICACIÓN INTERRUMPIDA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, bool isConnecting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusRow(),
          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: isConnecting ? null : () => _reconnect(context, ConnectionType.usbOtg),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ADB5),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFF00ADB5).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            icon: isConnecting && midi.connectionType == ConnectionType.usbOtg
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.usb, size: 20),
            label: Text(
              isConnecting && midi.connectionType == ConnectionType.usbOtg
                  ? 'RECONECTANDO USB...'
                  : 'VOLVER A CONECTAR (USB OTG)',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isConnecting ? null : () => _reconnect(context, ConnectionType.bluetoothBle),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blueAccent,
              side: const BorderSide(color: Colors.blueAccent, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: isConnecting && midi.connectionType == ConnectionType.bluetoothBle
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                : const Icon(Icons.bluetooth, size: 20),
            label: Text(
              isConnecting && midi.connectionType == ConnectionType.bluetoothBle
                  ? 'RECONECTANDO BLE...'
                  : 'VOLVER A CONECTAR (BLUETOOTH)',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onEnterDemoMode,
            child: const Text(
              'Continuar en Modo Demo (Sin pedalera)',
              style: TextStyle(color: Colors.white38, fontSize: 11, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final typeStr = midi.connectionType == ConnectionType.usbOtg ? 'Cable USB OTG' : 'Bluetooth BLE';
    return Row(
      children: [
        const Icon(Icons.settings_input_hdmi, size: 20, color: Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DISPOSITIVO OBJETIVO', style: TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
              Text('Boss GT-1B ($typeStr)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('OFFLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF5252))),
        ),
      ],
    );
  }

  Future<void> _reconnect(BuildContext context, ConnectionType type) async {
    final ok = await midi.connect(type: type);
    if (!context.mounted) return;
    if (!ok) {
      final typeLabel = type == ConnectionType.usbOtg ? 'cable USB OTG' : 'Bluetooth BLE';
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
}
