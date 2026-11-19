import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'midi_driver.dart';

/// Native Platform MIDI Driver for Android (and native platforms).
/// Communicates directly with android.media.midi.MidiManager via MethodChannel/EventChannel.
class PlatformMidiDriver implements MidiDriver {
  static const MethodChannel _channel = MethodChannel('com.example.tone_gt_studio/midi');
  static const EventChannel _eventChannel = EventChannel('com.example.tone_gt_studio/midi_events');

  bool _connected = false;
  String _deviceName = '';
  void Function(Uint8List data)? _onData;
  StreamSubscription? _eventSubscription;

  @override
  bool get isConnected => _connected;

  @override
  String get connectedDeviceName => _deviceName;

  @override
  Future<bool> init() async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>('init');
      return ok ?? false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('Error initializing native MIDI driver: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getDevices() async {
    try {
      final List<dynamic>? list = await _channel.invokeMethod<List<dynamic>>('getDevices');
      return list?.map((e) => e.toString()).toList() ?? [];
    } on MissingPluginException {
      return ['Boss GT-1B (Test)'];
    } catch (e) {
      debugPrint('Error enumerating native MIDI devices: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(String? deviceName) async {
    try {
      final res = await _channel.invokeMethod('connect', {'deviceName': deviceName});
      if (res is Map) {
        final success = res['success'] == true;
        if (success) {
          _connected = true;
          _deviceName = res['name']?.toString() ?? 'Boss GT-1B';
          _listenToEvents();
          return true;
        }
      } else if (res == true) {
        _connected = true;
        _deviceName = deviceName ?? 'Boss GT-1B';
        _listenToEvents();
        return true;
      }
      _connected = false;
      _deviceName = '';
      return false;
    } on MissingPluginException {
      _connected = true;
      _deviceName = deviceName ?? 'Boss GT-1B (Test)';
      return true;
    } catch (e) {
      debugPrint('Connection to native MIDI failed: $e');
      _connected = false;
      _deviceName = '';
      return false;
    }
  }

  void _listenToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((data) {
      if (data is Uint8List) {
        _onData?.call(data);
      } else if (data is List) {
        _onData?.call(Uint8List.fromList(data.cast<int>()));
      }
    }, onError: (err) {
      debugPrint('MIDI event stream error: $err');
    });
  }

  @override
  Future<void> disconnect() async {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    try {
      await _channel.invokeMethod('disconnect');
    } catch (_) {}
    _connected = false;
    _deviceName = '';
  }

  @override
  Future<bool> send(Uint8List data) async {
    if (!_connected) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>('send', {'data': data});
      return ok ?? false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('Error sending MIDI bytes: $e');
      return false;
    }
  }

  @override
  void setOnDataReceived(void Function(Uint8List data) callback) {
    _onData = callback;
  }
}
