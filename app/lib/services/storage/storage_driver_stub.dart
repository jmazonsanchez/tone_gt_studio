import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_driver.dart';

/// Platform Storage Driver for Native Mobile, Desktop and VM Unit Tests.
/// Persists data in an internal JSON file and synchronizes with an in-memory cache.
class PlatformStorageDriver implements StorageDriver {
  final Map<String, String> _cache = {};
  File? _file;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      // Determine persistence file path in user or system temp directory
      final baseDir = Directory.current.path;
      final storageDir = Directory('$baseDir/.storage');
      if (!storageDir.existsSync()) {
        storageDir.createSync(recursive: true);
      }
      _file = File('${storageDir.path}/tone_studio_db.json');
      if (_file!.existsSync()) {
        final content = _file!.readAsStringSync();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            _cache[entry.key] = entry.value.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Native storage init fallback to memory: $e');
    }
    _initialized = true;
  }

  void _persistToFile() {
    try {
      if (_file != null) {
        _file!.writeAsStringSync(jsonEncode(_cache));
      }
    } catch (e) {
      debugPrint('Error saving storage file: $e');
    }
  }

  @override
  String? getString(String key) {
    return _cache[key];
  }

  @override
  Future<bool> setString(String key, String value) async {
    _cache[key] = value;
    _persistToFile();
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    _persistToFile();
    return true;
  }

  @override
  Future<bool> clear() async {
    _cache.clear();
    _persistToFile();
    return true;
  }

  @override
  List<String> getKeys() {
    return _cache.keys.toList();
  }
}
