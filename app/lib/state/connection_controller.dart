import 'package:flutter/foundation.dart';
import '../core/transport/midi_transport.dart';
import '../protocol/gt1b_map.dart';
import '../protocol/roland_sysex.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// Único responsable del estado de conexión y activación del Modo Editor (Resuelve D2).
class ConnectionController extends ChangeNotifier {
  final MidiTransport transport;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get isConnecting => _status == ConnectionStatus.connecting;
  String get deviceName => transport.connectedDeviceName;
  String get errorMessage => _errorMessage;

  ConnectionController({required this.transport});

  /// Conecta con la GT-1B y activa el Modo Editor una sola vez.
  Future<bool> connect({String? deviceName}) async {
    _status = ConnectionStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    try {
      final ok = await transport.connect(deviceName: deviceName);
      if (ok) {
        _status = ConnectionStatus.connected;
        // Enviar handshake de Modo Editor una sola vez (Soluciona D2)
        final editorOn = RolandSysEx.buildDt1(
          address: Gt1bMap.editorCommunicationMode,
          data: [0x01],
        );
        await transport.send(editorOn);
      } else {
        _status = ConnectionStatus.disconnected;
        _errorMessage = 'No se pudo establecer conexión MIDI.';
      }
      notifyListeners();
      return ok;
    } catch (e) {
      _status = ConnectionStatus.disconnected;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Desconecta ordenadamente desactivando el Modo Editor.
  Future<void> disconnect() async {
    if (isConnected) {
      try {
        final editorOff = RolandSysEx.buildDt1(
          address: Gt1bMap.editorCommunicationMode,
          data: [0x00],
        );
        await transport.send(editorOff);
      } catch (_) {}
    }

    await transport.disconnect();
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }
}
