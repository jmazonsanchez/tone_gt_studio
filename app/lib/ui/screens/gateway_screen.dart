import 'package:flutter/material.dart';
import '../../services/midi_service.dart';

class GatewayScreen extends StatelessWidget {
  final MidiService midi;
  final VoidCallback onEnterDemoMode;

  const GatewayScreen({
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
      backgroundColor: const Color(0xFF0F0F14),
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
        // Left Column: Graphic & Title
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPedalIcon(),
              const SizedBox(height: 16),
              _buildBadge(),
              const SizedBox(height: 10),
              const Text(
                'Boss GT-1B Bass Studio',
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
                'Sincroniza tus 198 presets (U y P), línea de conexión y pedales en vivo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.3),
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Right Column: Connection Buttons
        Expanded(
          flex: 5,
          child: _buildActionButtons(context, isConnecting),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(BuildContext context, bool isConnecting) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPedalIcon(),
        const SizedBox(height: 20),
        _buildBadge(),
        const SizedBox(height: 12),
        const Text(
          'Boss GT-1B Bass Studio',
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
          'Conecta tu pedalera para sincronizar presets y efectos en vivo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 24),
        _buildActionButtons(context, isConnecting),
      ],
    );
  }

  Widget _buildPedalIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00ADB5).withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logoToneStudio.png',
        width: 140,
        height: 140,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1A1A26),
            child: const Icon(Icons.settings_input_hdmi, size: 48, color: Color(0xFF00ADB5)),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00ADB5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00ADB5).withValues(alpha: 0.4)),
      ),
      child: const Text(
        'PASO 1: CONECTAR A LA PEDALERA',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Color(0xFF00ADB5),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isConnecting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // USB OTG Button
        ElevatedButton.icon(
          onPressed: isConnecting ? null : () => _connect(context, ConnectionType.usbOtg),
          icon: isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Icon(Icons.usb, size: 20),
          label: Text(
            isConnecting ? 'CONECTANDO...' : 'CONECTAR POR CABLE USB OTG',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00ADB5),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
        ),

        const SizedBox(height: 10),

        // Bluetooth BLE Button
        OutlinedButton.icon(
          onPressed: isConnecting ? null : () => _connect(context, ConnectionType.bluetoothBle),
          icon: const Icon(Icons.bluetooth, size: 18),
          label: const Text(
            'CONECTAR VÍA BLUETOOTH BLE',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 16),

        // Demo Mode Button
        Center(
          child: TextButton.icon(
            onPressed: onEnterDemoMode,
            icon: const Icon(Icons.visibility, size: 14, color: Colors.white54),
            label: const Text(
              'Explorar en Modo Demo (Offline)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white54,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _connect(BuildContext context, ConnectionType type) async {
    final ok = await midi.connect(type: type);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '✅ Boss GT-1B conectada. Sincronizando presets y efectos...'
              : '⚠️ No se detectó la Boss GT-1B. Conecta el cable y reintenta.'),
          backgroundColor: ok ? Colors.teal : Colors.deepOrange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
