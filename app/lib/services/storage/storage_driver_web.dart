import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'storage_driver.dart';

@JS('toneStorageBridge')
external JSObject? get toneStorageBridge;

/// Web Storage Driver implementing persistent LocalStorage via toneStorageBridge.
class PlatformStorageDriver implements StorageDriver {
  @override
  Future<void> init() async {}

  @override
  String? getString(String key) {
    try {
      final bridge = toneStorageBridge;
      if (bridge != null) {
        final res = bridge.callMethod<JSString?>('getItem'.toJS, key.toJS);
        return res?.toDart;
      }
      final storage = globalContext['localStorage'] as JSObject?;
      final res = storage?.callMethod<JSString?>('getItem'.toJS, key.toJS);
      return res?.toDart;
    } catch (e) {
      debugPrint('Web storage getString error: $e');
      return null;
    }
  }

  @override
  Future<bool> setString(String key, String value) async {
    try {
      final bridge = toneStorageBridge;
      if (bridge != null) {
        final res = bridge.callMethod<JSBoolean>('setItem'.toJS, key.toJS, value.toJS);
        return res.toDart;
      }
      final storage = globalContext['localStorage'] as JSObject?;
      storage?.callMethod('setItem'.toJS, key.toJS, value.toJS);
      return true;
    } catch (e) {
      debugPrint('Web storage setString error: $e');
      return false;
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      final bridge = toneStorageBridge;
      if (bridge != null) {
        final res = bridge.callMethod<JSBoolean>('removeItem'.toJS, key.toJS);
        return res.toDart;
      }
      final storage = globalContext['localStorage'] as JSObject?;
      storage?.callMethod('removeItem'.toJS, key.toJS);
      return true;
    } catch (e) {
      debugPrint('Web storage remove error: $e');
      return false;
    }
  }

  @override
  Future<bool> clear() async {
    try {
      final bridge = toneStorageBridge;
      if (bridge != null) {
        final res = bridge.callMethod<JSBoolean>('clear'.toJS);
        return res.toDart;
      }
      final storage = globalContext['localStorage'] as JSObject?;
      storage?.callMethod('clear'.toJS);
      return true;
    } catch (e) {
      debugPrint('Web storage clear error: $e');
      return false;
    }
  }

  @override
  List<String> getKeys() {
    try {
      final bridge = toneStorageBridge;
      if (bridge != null) {
        final keys = bridge.callMethod<JSArray<JSString>>('getAllKeys'.toJS).toDart;
        return keys.map((k) => k.toDart).toList();
      }
      final storage = globalContext['localStorage'] as JSObject?;
      final length = (storage?['length'] as JSNumber?)?.toDartInt ?? 0;
      final list = <String>[];
      for (int i = 0; i < length; i++) {
        final k = storage?.callMethod<JSString?>('key'.toJS, i.toJS);
        if (k != null) list.add(k.toDart);
      }
      return list;
    } catch (e) {
      debugPrint('Web storage getKeys error: $e');
      return [];
    }
  }
}
