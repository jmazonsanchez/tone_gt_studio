import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_driver.dart';

/// Platform Storage Driver for Native Mobile (Android/iOS), Desktop and VM Unit Tests.
/// Persists data in an internal sandboxed JSON file and synchronizes with an in-memory cache.
class PlatformStorageDriver implements StorageDriver {
  final Map<String, String> _cache = {};
  File? _file;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      Directory? baseDir;
      try {
        baseDir = await getApplicationSupportDirectory();
      } catch (_) {
        try {
          baseDir = await getApplicationDocumentsDirectory();
        } catch (_) {}
      }

      baseDir ??= Directory(Directory.current.path);

      Directory storageDir;
      try {
        storageDir = Directory('${baseDir.path}/.storage');
        if (!storageDir.existsSync()) {
          storageDir.createSync(recursive: true);
        }
      } catch (e) {
        debugPrint('Failed to create storageDir in $baseDir: $e, falling back to system temp');
        storageDir = Directory('${Directory.systemTemp.path}/.tone_storage');
        if (!storageDir.existsSync()) {
          storageDir.createSync(recursive: true);
        }
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

  void _ensureFile() {
    if (_file != null) return;
    try {
      final storageDir = Directory('${Directory.systemTemp.path}/.tone_storage');
      if (!storageDir.existsSync()) {
        storageDir.createSync(recursive: true);
      }
      _file = File('${storageDir.path}/tone_studio_db.json');
    } catch (_) {}
  }

  void _persistToFile() {
    try {
      _ensureFile();
      if (_file != null) {
        _file!.writeAsStringSync(jsonEncode(_cache), flush: true);
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
