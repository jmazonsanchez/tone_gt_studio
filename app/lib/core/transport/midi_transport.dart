import 'dart:typed_data';

/// Interfaz abstracta para cualquier canal de transporte MIDI (Web, USB OTG, BLE, Fake/Mock).
abstract class MidiTransport {
  /// Si el transporte está actualmente conectado al dispositivo.
  bool get isConnected;

  /// Nombre del dispositivo conectado (ej. 'Boss GT-1B (USB)').
  String get connectedDeviceName;

  /// Flujo continuo de paquetes MIDI/SysEx entrantes desde el hardware.
  Stream<Uint8List> get onDataReceived;

  /// Inicializa la conexión con el dispositivo.
  Future<bool> connect({String? deviceName});

  /// Cierra la sesión activa.
  Future<void> disconnect();

  /// Envía un paquete MIDI o SysEx crudo al dispositivo.
  Future<void> send(Uint8List data);
}
