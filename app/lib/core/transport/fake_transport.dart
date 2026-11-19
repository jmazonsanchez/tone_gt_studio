import 'dart:async';
import 'dart:typed_data';
import 'midi_transport.dart';
import '../../protocol/gt_sysex.dart';

/// Simulador de Boss GT-1B en memoria para pruebas automáticas sin hardware.
class FakeTransport implements MidiTransport {
  bool _connected = false;
  final _controller = StreamController<Uint8List>.broadcast();
  final Map<String, int> _memory = {};

  bool simulateEchoOnWrite = true;
  Duration simulatedLatency = const Duration(milliseconds: 5);

  @override
  bool get isConnected => _connected;

  @override
  String get connectedDeviceName => 'Fake Boss GT-1B (Mock)';

  @override
  Stream<Uint8List> get onDataReceived => _controller.stream;

  FakeTransport() {
    _initDefaultMemory();
  }

  void _initDefaultMemory() {
    // Current Patch = 0 (U01)
    _setMem([0x00, 0x01, 0x00, 0x00], 0x00);
    _setMem([0x00, 0x01, 0x00, 0x01], 0x00);

    // Switches por defecto
    _setMem([0x60, 0x00, 0x00, 0x20], 0x00); // COMP OFF
    _setMem([0x60, 0x00, 0x00, 0x30], 0x01); // OD/DS ON
    _setMem([0x60, 0x00, 0x00, 0x50], 0x01); // PREAMP ON
    _setMem([0x60, 0x00, 0x01, 0x30], 0x00); // EQ OFF
    _setMem([0x60, 0x00, 0x01, 0x40], 0x00); // FX1 OFF
    _setMem([0x60, 0x00, 0x03, 0x4C], 0x00); // FX2 OFF
    _setMem([0x60, 0x00, 0x05, 0x60], 0x00); // DELAY OFF
    _setMem([0x60, 0x00, 0x06, 0x00], 0x00); // CHORUS OFF
    _setMem([0x60, 0x00, 0x06, 0x10], 0x00); // REVERB OFF
    _setMem([0x60, 0x00, 0x06, 0x20], 0x00); // WAH OFF
    _setMem([0x60, 0x00, 0x06, 0x33], 0x64); // FOOT VOL 100
    _setMem([0x60, 0x00, 0x06, 0x63], 0x01); // NS ON

    // Cadena de efectos por defecto auténtica GT-1B (60 00 07 20 y 10 00 07 20)
    for (int i = 0; i < GtSysEx.defaultHardwareChain.length; i++) {
      _setMem([0x60, 0x00, 0x07, 0x20 + i], GtSysEx.defaultHardwareChain[i]);
      _setMem([0x10, 0x00, 0x07, 0x20 + i], GtSysEx.defaultHardwareChain[i]);
    }
  }

  void _setMem(List<int> addr, int val) {
    _memory[_key(addr)] = val;
  }

  int _getMem(List<int> addr) {
    return _memory[_key(addr)] ?? 0;
  }

  String _key(List<int> addr) => addr.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  Future<bool> connect({String? deviceName}) async {
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<void> send(Uint8List data) async {
    if (!_connected || data.isEmpty) return;

    // 1. Identity Request (F0 7E 7F 06 01 F7)
    if (data.length == 6 && data[0] == 0xF0 && data[1] == 0x7E && data[3] == 0x06 && data[4] == 0x01) {
      final reply = Uint8List.fromList([
        0xF0, 0x7E, 0x00, 0x06, 0x02, 0x41, 0x3E, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7
      ]);
      _emitDelayed(reply);
      return;
    }

    // 2. Roland SysEx
    if (data.length >= 14 && data[0] == 0xF0 && data[1] == 0x41) {
      final cmd = data[7];
      final addr = data.sublist(8, 12);

      // RQ1: Data Request
      if (cmd == GtSysEx.commandRq1) {
        final sizeBytes = data.sublist(12, 16);
        final size = (sizeBytes[0] << 21) | (sizeBytes[1] << 14) | (sizeBytes[2] << 7) | sizeBytes[3];

        // Construir datos devueltos
        final payload = <int>[];
        for (int i = 0; i < size; i++) {
          final curAddr = [addr[0], addr[1], addr[2], addr[3] + i];
          payload.add(_getMem(curAddr));
        }

        final reply = GtSysEx.buildDt1Message(
          address: addr,
          data: payload,
        );
        _emitDelayed(reply);
        return;
      }

      // DT1: Data Set (Escritura desde la app)
      if (cmd == GtSysEx.commandDt1) {
        final payload = data.sublist(12, data.length - 2);
        for (int i = 0; i < payload.length; i++) {
          final curAddr = [addr[0], addr[1], addr[2], addr[3] + i];
          _setMem(curAddr, payload[i]);
        }

        // Simular eco que la GT-1B real envía de vuelta (Hallazgo H3)
        if (simulateEchoOnWrite) {
          final echo = GtSysEx.buildDt1Message(address: addr, data: payload);
          _emitDelayed(echo);
        }
      }
    }
  }

  void _emitDelayed(Uint8List packet) {
    Timer(simulatedLatency, () {
      if (_connected && !_controller.isClosed) {
        _controller.add(packet);
      }
    });
  }

  /// Inyectar un evento espontáneo simulando que el usuario presionó algo en la pedalera
  void emitHardwareEvent(Uint8List packet) {
    if (_connected && !_controller.isClosed) {
      _controller.add(packet);
    }
  }

  void dispose() {
    _controller.close();
  }
}
