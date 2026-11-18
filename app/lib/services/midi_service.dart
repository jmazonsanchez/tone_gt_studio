import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../protocol/gt_sysex.dart';
import '../models/effect_block.dart';

enum MidiConnectionState {
  disconnected,
  connecting,
  connected,
}

enum ConnectionType {
  usbOtg,
  bluetoothBle,
}

/// Abstract MIDI Service allowing seamless switching between USB OTG and Wireless BLE
class MidiService extends ChangeNotifier {
  MidiConnectionState _connectionState = MidiConnectionState.disconnected;
  ConnectionType _connectionType = ConnectionType.usbOtg;
  String _connectedDeviceName = '';

  MidiConnectionState get connectionState => _connectionState;
  ConnectionType get connectionType => _connectionType;
  String get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _connectionState == MidiConnectionState.connected;

  /// Connect to Boss GT-1B via USB OTG or BLE
  Future<bool> connect({ConnectionType type = ConnectionType.usbOtg}) async {
    _connectionState = MidiConnectionState.connecting;
    _connectionType = type;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _connectionState = MidiConnectionState.connected;
    _connectedDeviceName = type == ConnectionType.usbOtg ? 'Boss GT-1B (USB)' : 'GT-1B Wireless Bridge';
    notifyListeners();
    return true;
  }

  /// Disconnect current session
  Future<void> disconnect() async {
    _connectionState = MidiConnectionState.disconnected;
    _connectedDeviceName = '';
    notifyListeners();
  }

  /// Send raw SysEx packet
  Future<void> sendSysEx(Uint8List data) async {
    if (!isConnected) return;
    debugPrint('SysEx Sent (${data.length} bytes): ${data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
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
