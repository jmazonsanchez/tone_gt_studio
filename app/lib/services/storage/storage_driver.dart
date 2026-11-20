import 'storage_driver_stub.dart'
    if (dart.library.js) 'storage_driver_web.dart';

/// Low-level key-value storage driver interface for ToneStudio persistence.
abstract class StorageDriver {
  Future<void> init();
  String? getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
  Future<bool> clear();
  List<String> getKeys();

  factory StorageDriver() => PlatformStorageDriver();
}

/// In-memory storage driver for testing and isolated sessions.
class MemoryStorageDriver implements StorageDriver {
  final Map<String, String> _memory = {};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _memory[key];

  @override
  Future<bool> setString(String key, String value) async {
    _memory[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _memory.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _memory.clear();
    return true;
  }

  @override
  List<String> getKeys() => _memory.keys.toList();
}
