import 'dart:async';
import 'dart:typed_data';
import '../core/transport/midi_transport.dart';
import '../protocol/roland_sysex.dart';

/// Elemento en cola para escribir un parámetro hacia la pedalera.
class _PendingWrite {
  final List<int> address;
  final List<int> data;
  final DateTime timestamp;

  _PendingWrite({
    required this.address,
    required this.data,
  }) : timestamp = DateTime.now();

  String get key => address.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Cola de escritura hacia la GT-1B con regulación de velocidad (throttling)
/// y supresión de eco de retorno (Solución a H3 y prevención de saturación de bus).
class WriteQueue {
  final MidiTransport transport;
  final Duration minInterval;
  final Duration echoTtl;

  final Map<String, _PendingWrite> _latestPerAddress = {};
  final List<_PendingWrite> _recentSentWrites = [];
  Timer? _drainTimer;
  bool _isSending = false;

  WriteQueue({
    required this.transport,
    this.minInterval = const Duration(milliseconds: 30), // ~33 mensajes/segundo máx
    this.echoTtl = const Duration(milliseconds: 800),
  });

  /// Encola la escritura de un parámetro. Si ya existía un cambio pendiente
  /// para la misma dirección (ej. arrastre rápido de un knob), lo reemplaza.
  void queueWrite(List<int> address, List<int> data) {
    assert(address.length == 4, 'La dirección debe tener 4 bytes');
    final write = _PendingWrite(address: address, data: data);
    _latestPerAddress[write.key] = write;

    _scheduleDrain();
  }

  void _scheduleDrain() {
    if (_drainTimer?.isActive ?? false) return;
    _drainTimer = Timer(minInterval, _drain);
  }

  Future<void> _drain() async {
    if (_isSending || _latestPerAddress.isEmpty || !transport.isConnected) {
      return;
    }

    _isSending = true;
    try {
      final firstKey = _latestPerAddress.keys.first;
      final write = _latestPerAddress.remove(firstKey)!;

      // Registrar en la lista de ecos esperados
      _cleanupOldEchos();
      _recentSentWrites.add(write);

      // Enviar trama DT1
      final packet = RolandSysEx.buildDt1(address: write.address, data: write.data);
      await transport.send(packet);
    } finally {
      _isSending = false;
      if (_latestPerAddress.isNotEmpty) {
        _scheduleDrain();
      }
    }
  }

  /// Verifica si un DT1 entrante de la pedalera es el eco de una escritura que enviamos nosotros.
  /// Si es nuestro eco, devuelve true para que el EventRouter lo ignore y no genere bucles (H3).
  bool consumeEchoIfMatches(List<int> address, Uint8List data) {
    _cleanupOldEchos();
    final idx = _recentSentWrites.indexWhere((sent) {
      if (!RolandSysEx.addressMatches(sent.address, address)) return false;
      if (sent.data.length != data.length) return false;
      for (int i = 0; i < data.length; i++) {
        if (sent.data[i] != data[i]) return false;
      }
      return true;
    });

    if (idx >= 0) {
      _recentSentWrites.removeAt(idx);
      return true; // Es nuestro eco, ignorar
    }
    return false;
  }

  void _cleanupOldEchos() {
    final now = DateTime.now();
    _recentSentWrites.removeWhere((w) => now.difference(w.timestamp) > echoTtl);
  }

  void dispose() {
    _drainTimer?.cancel();
    _latestPerAddress.clear();
    _recentSentWrites.clear();
  }
}
