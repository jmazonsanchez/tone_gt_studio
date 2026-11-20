import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/device_config.dart';
import '../../models/quick_preset.dart';
import 'storage_driver.dart';

/// Central database service for ToneStudio managing persistent configuration
/// per hardware pedal device, live quick presets, appearance, and utilities.
class AppDatabase extends ChangeNotifier {
  static final AppDatabase instance = AppDatabase();

  final StorageDriver _driver;
  bool _isInitialized = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  AppDatabase({StorageDriver? driver}) : _driver = driver ?? StorageDriver();

  static const String keyPrefixDevice = 'tone_device_config_';
  static const String keyThemeMode = 'tone_app_theme_mode';
  static const String keyActiveDeviceId = 'tone_app_active_device_id';
  static const String defaultDeviceId = 'boss_gt1b';

  /// Initialize database and ensure default Boss GT-1B configuration exists
  Future<void> init() async {
    if (_isInitialized) return;
    await _driver.init();

    // Ensure baseline configuration for Boss GT-1B exists
    final rawGt1b = _driver.getString('$keyPrefixDevice$defaultDeviceId');
    if (rawGt1b == null || rawGt1b.isEmpty) {
      final defaultConfig = DeviceConfig.defaultGt1b();
      await saveDeviceConfig(defaultConfig, notify: false);
    }

    _isInitialized = true;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // PER-DEVICE CONFIGURATION PERSISTENCE
  // -------------------------------------------------------------

  /// Retrieve persistent configuration for specified hardware device
  DeviceConfig getDeviceConfig([String deviceId = defaultDeviceId]) {
    final raw = _driver.getString('$keyPrefixDevice$deviceId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return DeviceConfig.fromJson(decoded);
      } catch (e) {
        debugPrint('Error decoding device config for $deviceId: $e');
      }
    }
    return deviceId == defaultDeviceId
        ? DeviceConfig.defaultGt1b()
        : DeviceConfig(
            deviceId: deviceId,
            deviceName: 'Dispositivo MIDI ($deviceId)',
            updatedAt: DateTime.now(),
          );
  }

  /// Save persistent configuration for specified device
  Future<void> saveDeviceConfig(DeviceConfig config, {bool notify = true}) async {
    final encoded = jsonEncode(config.toJson());
    await _driver.setString('$keyPrefixDevice${config.deviceId}', encoded);
    if (config.quickPresets.isEmpty) {
      await _driver.remove('$keyPrefixQuickPresets${config.deviceId}');
    } else {
      try {
        final rawList = jsonEncode(config.quickPresets.map((p) => p.toJson()).toList());
        await _driver.setString('$keyPrefixQuickPresets${config.deviceId}', rawList);
      } catch (_) {}
    }
    if (notify && !_isDisposed) {
      notifyListeners();
    }
  }

  /// List all registered device configurations in the database
  List<DeviceConfig> getAllDeviceConfigs() {
    final keys = _driver.getKeys();
    final configs = <DeviceConfig>[];
    for (final key in keys) {
      if (key.startsWith(keyPrefixDevice)) {
        final raw = _driver.getString(key);
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            configs.add(DeviceConfig.fromJson(decoded));
          } catch (_) {}
        }
      }
    }
    if (configs.isEmpty) {
      configs.add(DeviceConfig.defaultGt1b());
    }
    return configs;
  }

  /// Reset a device's settings to factory default
  Future<void> resetDeviceConfig(String deviceId) async {
    await _driver.remove('$keyPrefixQuickPresets$deviceId');
    if (deviceId == defaultDeviceId) {
      await saveDeviceConfig(DeviceConfig.defaultGt1b());
    } else {
      await _driver.remove('$keyPrefixDevice$deviceId');
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // LIVE QUICK PRESETS (ACCESOS DIRECTOS PARA EL EN VIVO)
  // -------------------------------------------------------------

  static const String keyPrefixQuickPresets = 'tone_quick_presets_';

  /// Get live performance quick presets for active device
  List<QuickPreset> getQuickPresets([String deviceId = defaultDeviceId]) {
    final config = getDeviceConfig(deviceId);
    if (config.quickPresets.isNotEmpty) {
      return config.quickPresets;
    }
    final raw = _driver.getString('$keyPrefixQuickPresets$deviceId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((p) => QuickPreset.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
      } catch (_) {}
    }
    return config.quickPresets;
  }

  /// Persist modified live performance quick presets
  Future<void> saveQuickPresets(List<QuickPreset> presets, [String deviceId = defaultDeviceId]) async {
    final current = getDeviceConfig(deviceId);
    final updated = current.copyWith(
      quickPresets: presets,
      updatedAt: DateTime.now(),
    );
    await saveDeviceConfig(updated);
    try {
      final rawList = jsonEncode(presets.map((p) => p.toJson()).toList());
      await _driver.setString('$keyPrefixQuickPresets$deviceId', rawList);
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // THEME MODE PERSISTENCE (MODO OSCURO / CLARO)
  // -------------------------------------------------------------

  /// Get saved appearance theme mode ('dark' | 'light' | 'system')
  String getThemeMode() {
    return _driver.getString(keyThemeMode) ?? 'dark';
  }

  /// Persist appearance theme mode
  Future<void> saveThemeMode(String mode) async {
    await _driver.setString(keyThemeMode, mode);
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // ACTIVE DEVICE & UTILITIES PERSISTENCE
  // -------------------------------------------------------------

  /// Get currently active device ID
  String getActiveDeviceId() {
    return _driver.getString(keyActiveDeviceId) ?? defaultDeviceId;
  }

  /// Persist currently active device ID
  Future<void> setActiveDeviceId(String deviceId) async {
    await _driver.setString(keyActiveDeviceId, deviceId);
    notifyListeners();
  }

  /// Update metronome preferences in device profile
  Future<void> saveMetronomeSettings({
    String deviceId = defaultDeviceId,
    int? bpm,
    int? timeSignature,
    bool? visualOnly,
  }) async {
    final current = getDeviceConfig(deviceId);
    final updated = current.copyWith(
      metronomeBpm: bpm ?? current.metronomeBpm,
      metronomeTimeSignature: timeSignature ?? current.metronomeTimeSignature,
      metronomeVisualOnly: visualOnly ?? current.metronomeVisualOnly,
      updatedAt: DateTime.now(),
    );
    await saveDeviceConfig(updated);
  }

  /// Update phrase loop preferences in device profile
  Future<void> savePhraseLoopSettings({
    String deviceId = defaultDeviceId,
    int? timerSeconds,
    String? mode,
  }) async {
    final current = getDeviceConfig(deviceId);
    final updated = current.copyWith(
      phraseLoopTimerSeconds: timerSeconds ?? current.phraseLoopTimerSeconds,
      phraseLoopMode: mode ?? current.phraseLoopMode,
      updatedAt: DateTime.now(),
    );
    await saveDeviceConfig(updated);
  }
}
