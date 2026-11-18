import 'dart:typed_data';
import 'midi_driver_stub.dart'
    if (dart.library.js) 'midi_driver_web.dart';

abstract class MidiDriver {
  bool get isConnected;
  String get connectedDeviceName;
  Future<bool> init();
  Future<List<String>> getDevices();
  Future<bool> connect(String? deviceName);
  Future<void> disconnect();
  Future<bool> send(Uint8List data);
  void setOnDataReceived(void Function(Uint8List data) callback);

  factory MidiDriver() => PlatformMidiDriver();
}
