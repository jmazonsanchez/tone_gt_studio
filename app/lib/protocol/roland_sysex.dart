import 'dart:typed_data';

/// Mensaje DT1 (Data Set) parseado de Roland SysEx.
class Dt1Message {
  final List<int> address;
  final Uint8List data;

  const Dt1Message({required this.address, required this.data});
}

/// Motor de bajo nivel para el protocolo System Exclusive de Roland / Boss.
class RolandSysEx {
  static const int manufacturerId = 0x41; // Roland Corporation
  static const int defaultDeviceId = 0x00;
  static const List<int> modelIdGt1b = [0x00, 0x00, 0x00, 0x3E];

  static const int commandRq1 = 0x11; // Data Request 1
  static const int commandDt1 = 0x12; // Data Set 1

  /// Calcula el Checksum estándar de Roland de 7 bits:
  /// Checksum = (128 - (sum % 128)) & 0x7F
  static int calculateChecksum(List<int> bytes) {
    int sum = 0;
    for (final b in bytes) {
      sum += b;
    }
    return (128 - (sum % 128)) & 0x7F;
  }

  /// Construye un paquete DT1 (Data Set) para enviar datos a la pedalera.
  static Uint8List buildDt1({
    required List<int> address,
    required List<int> data,
    List<int> modelId = modelIdGt1b,
    int deviceId = defaultDeviceId,
  }) {
    assert(address.length == 4, 'La dirección Roland debe tener exactamente 4 bytes');
    final payload = <int>[...address, ...data];
    final chk = calculateChecksum(payload);

    return Uint8List.fromList([
      0xF0,
      manufacturerId,
      deviceId,
      ...modelId,
      commandDt1,
      ...payload,
      chk,
      0xF7,
    ]);
  }

  /// Construye un paquete RQ1 (Data Request) para solicitar datos al equipo.
  static Uint8List buildRq1({
    required List<int> address,
    required int size,
    List<int> modelId = modelIdGt1b,
    int deviceId = defaultDeviceId,
  }) {
    assert(address.length == 4, 'La dirección Roland debe tener exactamente 4 bytes');
    final sizeBytes = [
      (size >> 21) & 0x7F,
      (size >> 14) & 0x7F,
      (size >> 7) & 0x7F,
      size & 0x7F,
    ];

    final payload = <int>[...address, ...sizeBytes];
    final chk = calculateChecksum(payload);

    return Uint8List.fromList([
      0xF0,
      manufacturerId,
      deviceId,
      ...modelId,
      commandRq1,
      ...payload,
      chk,
      0xF7,
    ]);
  }

  /// Parsea un paquete SysEx entrante y extrae el mensaje DT1 si es válido.
  static Dt1Message? parseDt1(Uint8List packet) {
    if (packet.length < 14) return null;
    if (packet.first != 0xF0 || packet.last != 0xF7) return null;
    if (packet[1] != manufacturerId) return null;
    if (packet[7] != commandDt1) return null;

    final address = packet.sublist(8, 12).toList();
    // Los datos van desde el índice 12 hasta antes del checksum y F7
    final data = packet.sublist(12, packet.length - 2);

    return Dt1Message(address: address, data: data);
  }

  /// Compara con exactitud si dos direcciones de 4 bytes son idénticas (Soluciona D1).
  static bool addressMatches(List<int> a, List<int> b) {
    if (a.length < 4 || b.length < 4) return false;
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2] && a[3] == b[3];
  }
}
