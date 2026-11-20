import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/transport/midi_transport.dart';
import '../protocol/gt_sysex.dart';
import '../models/effect_block.dart';
import 'midi/midi_driver.dart';
import 'storage/app_database.dart';

enum MidiConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

enum ConnectionType {
  usbOtg,
  bluetoothBle,
}

/// MIDI Service for Boss GT-1B and GT-1 communication
class MidiService extends ChangeNotifier implements MidiTransport {
  final MidiDriver _driver = MidiDriver();
  final AppDatabase? _database;
  final _sysExController = StreamController<Uint8List>.broadcast();

  MidiConnectionState _connectionState = MidiConnectionState.disconnected;
  ConnectionType _connectionType = ConnectionType.usbOtg;
  String _connectedDeviceName = '';
  String _lastConnectedDevice = '';
  bool _hasHadActiveConnection = false;
  bool _autoReconnect = true;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  MidiConnectionState get connectionState => _connectionState;
  ConnectionType get connectionType => _connectionType;
  @override
  String get connectedDeviceName => _connectedDeviceName;
  @override
  bool get isConnected => _connectionState == MidiConnectionState.connected;
  bool get hasHadActiveConnection => _hasHadActiveConnection;
  bool get isAutoReconnecting => _connectionState == MidiConnectionState.reconnecting;
  bool get autoReconnect => _autoReconnect;
  set autoReconnect(bool val) {
    _autoReconnect = val;
    if (!val) _cancelReconnectTimer();
    final db = _database;
    if (db != null) {
      final current = db.getDeviceConfig('boss_gt1b');
      db.saveDeviceConfig(current.copyWith(autoReconnect: val), notify: false);
    }
  }
  int get reconnectAttempts => _reconnectAttempts;

  @override
  Stream<Uint8List> get onDataReceived => _sysExController.stream;
  Stream<Uint8List> get onSysExReceived => _sysExController.stream;

  MidiService({AppDatabase? database}) : _database = database ?? AppDatabase.instance {
    _driver.setOnDataReceived(_handleIncomingMidi);
    _driver.setOnDisconnected(handleUnexpectedDisconnection);
    _loadDevicePreferences();
  }

  void _loadDevicePreferences() {
    final db = _database;
    if (db == null) return;
    final config = db.getDeviceConfig('boss_gt1b');
    _autoReconnect = config.autoReconnect;
    _connectionType = config.lastConnectionType == 'bluetoothBle'
        ? ConnectionType.bluetoothBle
        : ConnectionType.usbOtg;
  }

  @override
  void dispose() {
    _cancelReconnectTimer();
    _sysExController.close();
    super.dispose();
  }

  void _handleIncomingMidi(Uint8List data) {
    if (data.isNotEmpty) {
      _sysExController.add(data);
    }
  }

  @visibleForTesting
  void handleIncomingDataForTesting(Uint8List data) {
    _handleIncomingMidi(data);
  }

  @visibleForTesting
  void setConnectedForTesting(bool connected, {ConnectionType type = ConnectionType.usbOtg}) {
    _connectionState = connected ? MidiConnectionState.connected : MidiConnectionState.disconnected;
    _connectionType = type;
    if (connected) {
      _connectedDeviceName = 'Boss GT-1B';
      _hasHadActiveConnection = true;
    }
    notifyListeners();
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  void cancelAutoReconnect() {
    _cancelReconnectTimer();
    if (_connectionState == MidiConnectionState.reconnecting) {
      _connectionState = MidiConnectionState.disconnected;
      notifyListeners();
    }
  }

  /// Triggered when the physical connection is lost unexpectedly
  void handleUnexpectedDisconnection() {
    if (!isConnected && _connectionState != MidiConnectionState.reconnecting) return;
    _driver.disconnect();
    if (_autoReconnect) {
      _connectionState = MidiConnectionState.reconnecting;
      notifyListeners();
      _startReconnectLoop();
    } else {
      _connectionState = MidiConnectionState.disconnected;
      _connectedDeviceName = '';
      notifyListeners();
    }
  }

  void _startReconnectLoop() {
    _cancelReconnectTimer();
    _reconnectAttempts = 0;
    _reconnectTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      _reconnectAttempts++;
      final success = await _attemptReconnect();
      if (success) {
        _cancelReconnectTimer();
      }
    });
  }

  Future<bool> reconnect() async {
    return await _attemptReconnect();
  }

  Future<bool> _attemptReconnect() async {
    try {
      final success = await _driver.connect(_lastConnectedDevice.isNotEmpty ? _lastConnectedDevice : null);
      if (success) {
        _connectionState = MidiConnectionState.connected;
        _connectedDeviceName = _driver.connectedDeviceName;
        _hasHadActiveConnection = true;
        await sendSysEx(GtSysEx.buildEditorMode(enable: true));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Reconnection attempt failed: $e');
    }
    return false;
  }

  /// Discover available MIDI devices
  Future<List<String>> getAvailableDevices() async {
    await _driver.init();
    return await _driver.getDevices();
  }

  /// Connect to Boss GT-1B via USB OTG or Web MIDI
  @override
  Future<bool> connect({ConnectionType type = ConnectionType.usbOtg, String? deviceName}) async {
    _cancelReconnectTimer();
    _connectionState = MidiConnectionState.connecting;
    _connectionType = type;
    notifyListeners();

    try {
      final success = await _driver.connect(deviceName);
      if (success) {
        _connectionState = MidiConnectionState.connected;
        _connectedDeviceName = _driver.connectedDeviceName;
        _lastConnectedDevice = _connectedDeviceName;
        _hasHadActiveConnection = true;
        final db = _database;
        if (db != null) {
          final typeStr = type == ConnectionType.bluetoothBle ? 'bluetoothBle' : 'usbOtg';
          final current = db.getDeviceConfig('boss_gt1b');
          db.saveDeviceConfig(current.copyWith(
            lastConnectionType: typeStr,
            autoReconnect: _autoReconnect,
          ), notify: false);
        }
        // Activate Roland Editor Communication Mode for live bidirectional parameter sync
        await sendSysEx(GtSysEx.buildEditorMode(enable: true));
      } else {
        _connectionState = MidiConnectionState.disconnected;
        _connectedDeviceName = '';
      }
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error connecting to MIDI device: $e');
      _connectionState = MidiConnectionState.disconnected;
      _connectedDeviceName = '';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect current session
  @override
  Future<void> disconnect() async {
    _cancelReconnectTimer();
    if (isConnected) {
      try {
        await sendSysEx(GtSysEx.buildEditorMode(enable: false));
      } catch (_) {}
    }
    await _driver.disconnect();
    _connectionState = MidiConnectionState.disconnected;
    _connectedDeviceName = '';
    notifyListeners();
  }

  /// Send raw SysEx packet
  @override
  Future<void> send(Uint8List data) async => sendSysEx(data);

  Future<void> sendSysEx(Uint8List data) async {
    if (!isConnected) return;
    await _driver.send(data);
  }

  /// Send an RQ1 SysEx request and wait for the matching DT1 reply packet
  Future<Uint8List?> sendSysExRequest(
    Uint8List request, {
    Duration timeout = const Duration(milliseconds: 600),
  }) async {
    if (!isConnected) return null;
    final completer = Completer<Uint8List?>();

    assert(request.length >= 12, 'Request must contain address bytes');
    final reqAddress = request.sublist(8, 12);

    final sub = onSysExReceived.listen((packet) {
      if (packet.length >= 12 && packet[0] == 0xF0 && packet[7] == GtSysEx.commandDt1) {
        // Compare complete 4-byte address (Soluciona D1)
        if (packet[8] == reqAddress[0] &&
            packet[9] == reqAddress[1] &&
            packet[10] == reqAddress[2] &&
            packet[11] == reqAddress[3]) {
          if (!completer.isCompleted) {
            completer.complete(packet);
          }
        }
      }
    });

    await sendSysEx(request);

    try {
      final reply = await completer.future.timeout(timeout);
      return reply;
    } catch (_) {
      return null;
    } finally {
      await sub.cancel();
    }
  }

  /// Change Patch (U01 - U99) using Roland SysEx DT1
  Future<void> changePatch(int patchIndex) async {
    final msg = GtSysEx.buildPatchChange(patchIndex);
    await sendSysEx(msg);
  }

  /// Toggle Effect Block
  Future<void> toggleEffect(EffectCategory category, bool isEnabled) async {
    final msg = GtSysEx.buildEffectToggle(category, isEnabled);
    await sendSysEx(msg);
  }

  /// Toggle Tuner
  Future<void> toggleTuner(bool enable) async {
    final msg = GtSysEx.buildTunerToggle(enable: enable);
    await sendSysEx(msg);
  }

  /// Toggle Phrase Loop Mode (00 00 01 00)
  Future<void> togglePhraseLoop(bool enable) async {
    final msg = GtSysEx.buildPhraseLoopToggle(enable: enable);
    await sendSysEx(msg);
  }

  /// Set Phrase Loop Playback Level (00 00 01 04)
  Future<void> setPhraseLoopLevel(int level) async {
    final msg = GtSysEx.buildPhraseLoopLevel(level);
    await sendSysEx(msg);
  }

  /// Set Phrase Loop Rec Mode (00 00 01 02)
  Future<void> setPhraseLoopRecMode(int mode) async {
    final msg = GtSysEx.buildPhraseLoopRecMode(mode);
    await sendSysEx(msg);
  }

  /// Send individual parameter value change in real time via SysEx DT1
  Future<void> sendParameterValue(List<int> address, int value) async {
    final msg = GtSysEx.buildDt1Message(
      address: address,
      data: [value & 0x7F],
    );
    await sendSysEx(msg);
  }
}
