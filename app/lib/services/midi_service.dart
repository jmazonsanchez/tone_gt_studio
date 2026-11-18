import 'dart:async';
import 'package:flutter/foundation.dart';
import '../protocol/gt_sysex.dart';
import '../models/effect_block.dart';
import 'midi/midi_driver.dart';

enum MidiConnectionState {
  disconnected,
  connecting,
  connected,
}

enum ConnectionType {
  usbOtg,
  bluetoothBle,
}

/// MIDI Service for Boss GT-1B and GT-1 communication
class MidiService extends ChangeNotifier {
  final MidiDriver _driver = MidiDriver();

  MidiConnectionState _connectionState = MidiConnectionState.disconnected;
  ConnectionType _connectionType = ConnectionType.usbOtg;
  String _connectedDeviceName = '';

  MidiConnectionState get connectionState => _connectionState;
  ConnectionType get connectionType => _connectionType;
  String get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _connectionState == MidiConnectionState.connected;

  MidiService() {
    _driver.setOnDataReceived(_handleIncomingMidi);
  }

  void _handleIncomingMidi(Uint8List data) {
    debugPrint('SysEx Received (${data.length} bytes): ${data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
  }

  /// Discover available MIDI devices
  Future<List<String>> getAvailableDevices() async {
    await _driver.init();
    return await _driver.getDevices();
  }

  /// Connect to Boss GT-1B via USB OTG or Web MIDI
  Future<bool> connect({ConnectionType type = ConnectionType.usbOtg, String? deviceName}) async {
    _connectionState = MidiConnectionState.connecting;
    _connectionType = type;
    notifyListeners();

    try {
      final success = await _driver.connect(deviceName);
      if (success) {
        _connectionState = MidiConnectionState.connected;
        _connectedDeviceName = _driver.connectedDeviceName;
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
  Future<void> disconnect() async {
    await _driver.disconnect();
    _connectionState = MidiConnectionState.disconnected;
    _connectedDeviceName = '';
    notifyListeners();
  }

  /// Send raw SysEx packet
  Future<void> sendSysEx(Uint8List data) async {
    if (!isConnected) return;
    debugPrint('SysEx Sent (${data.length} bytes): ${data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
    await _driver.send(data);
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

  /// Send individual parameter value change in real time via SysEx DT1
  Future<void> sendParameterValue(List<int> address, int value) async {
    final msg = GtSysEx.buildDt1Message(
      address: address,
      data: [value & 0x7F],
    );
    await sendSysEx(msg);
  }
}
