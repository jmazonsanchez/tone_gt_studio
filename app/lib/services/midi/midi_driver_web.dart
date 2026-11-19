import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'midi_driver.dart';

@JS('toneMidiBridge')
external JSObject? get toneMidiBridge;

class PlatformMidiDriver implements MidiDriver {
  bool _connected = false;
  String _deviceName = '';
  void Function(Uint8List data)? _onData;
  void Function()? _onDisconnected;

  @override
  bool get isConnected => _connected;

  @override
  String get connectedDeviceName => _deviceName;

  @override
  Future<bool> init() async {
    try {
      final bridge = toneMidiBridge;
      if (bridge == null) {
        debugPrint('toneMidiBridge not found on window object');
        return false;
      }
      final promise = bridge.callMethod<JSPromise<JSBoolean>>('requestAccess'.toJS);
      final JSBoolean result = await promise.toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('Error initializing Web MIDI: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getDevices() async {
    try {
      final bridge = toneMidiBridge;
      if (bridge == null) return [];
      final jsDevices = bridge.callMethod<JSArray<JSObject>>('getDevices'.toJS).toDart;
      final List<String> list = [];
      for (final item in jsDevices) {
        final name = item.getProperty<JSString?>('name'.toJS)?.toDart;
        if (name != null) list.add(name);
      }
      return list;
    } catch (e) {
      debugPrint('Error getting MIDI devices: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(String? deviceName) async {
    try {
      final bridge = toneMidiBridge;
      if (bridge == null) return false;

      await init();

      final callback = ((JSArray<JSNumber> data) {
        if (_onData != null) {
          final list = data.toDart.map((n) => n.toDartInt).toList();
          _onData!(Uint8List.fromList(list));
        }
      }).toJS;

      bridge.callMethod('setMessageCallback'.toJS, callback);

      final target = deviceName != null ? deviceName.toJS : 'GT-1B'.toJS;
      final bool success = bridge.callMethod<JSBoolean>('connect'.toJS, target).toDart;
      _connected = success;
      if (success) {
        _deviceName = deviceName ?? 'Boss GT-1B (USB)';
        _bindDisconnectCallback();
      }
      return success;
    } catch (e) {
      debugPrint('Error connecting to Web MIDI: $e');
      return false;
    }
  }

  void _bindDisconnectCallback() {
    try {
      final bridge = toneMidiBridge;
      if (bridge != null) {
        final callback = (() {
          _connected = false;
          _deviceName = '';
          _onDisconnected?.call();
        }).toJS;
        bridge.callMethod('setDisconnectCallback'.toJS, callback);
      }
    } catch (e) {
      debugPrint('Error registering Web MIDI disconnect callback: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      final bridge = toneMidiBridge;
      bridge?.callMethod('disconnect'.toJS);
    } catch (e) {
      debugPrint('Error disconnecting Web MIDI: $e');
    } finally {
      _connected = false;
      _deviceName = '';
    }
  }

  @override
  Future<bool> send(Uint8List data) async {
    if (!_connected) return false;
    try {
      final bridge = toneMidiBridge;
      if (bridge == null) return false;
      final jsData = data.toJS;
      final bool res = bridge.callMethod<JSBoolean>('send'.toJS, jsData).toDart;
      return res;
    } catch (e) {
      debugPrint('Error sending SysEx: $e');
      return false;
    }
  }

  @override
  void setOnDataReceived(void Function(Uint8List data) callback) {
    _onData = callback;
  }

  @override
  void setOnDisconnected(void Function() callback) {
    _onDisconnected = callback;
    _bindDisconnectCallback();
  }
}
