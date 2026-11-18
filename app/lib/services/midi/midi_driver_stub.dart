import 'dart:typed_data';
import 'midi_driver.dart';

class PlatformMidiDriver implements MidiDriver {
  bool _connected = false;
  String _deviceName = '';
  void Function(Uint8List data)? _onData;

  @override
  bool get isConnected => _connected;

  @override
  String get connectedDeviceName => _deviceName;

  @override
  Future<bool> init() async => true;

  @override
  Future<List<String>> getDevices() async => ['Boss GT-1B (Mock)'];

  @override
  Future<bool> connect(String? deviceName) async {
    _connected = true;
    _deviceName = deviceName ?? 'Boss GT-1B';
    // Trigger mock handshake echo if listener attached
    _onData?.call(Uint8List.fromList([0xF0, 0x7E, 0x00, 0x06, 0x02, 0x41, 0x3E, 0x03, 0xF7]));
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _deviceName = '';
  }

  @override
  Future<bool> send(Uint8List data) async {
    return true;
  }

  @override
  void setOnDataReceived(void Function(Uint8List data) callback) {
    _onData = callback;
  }
}
