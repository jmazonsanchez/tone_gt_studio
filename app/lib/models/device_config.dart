import 'quick_preset.dart';

/// Model representing persistent settings and preferences for a specific hardware pedal device.
class DeviceConfig {
  final String deviceId;
  final String deviceName;
  final String lastConnectionType; // 'usbOtg' | 'bluetoothBle'
  final bool autoReconnect;
  final int lastPatchIndex;
  final List<QuickPreset> quickPresets;
  final int metronomeBpm;
  final int metronomeTimeSignature;
  final bool metronomeVisualOnly;
  final int phraseLoopTimerSeconds;
  final String phraseLoopMode;
  final String customNickname;
  final DateTime updatedAt;

  const DeviceConfig({
    required this.deviceId,
    required this.deviceName,
    this.lastConnectionType = 'usbOtg',
    this.autoReconnect = true,
    this.lastPatchIndex = 0,
    this.quickPresets = const [],
    this.metronomeBpm = 120,
    this.metronomeTimeSignature = 4,
    this.metronomeVisualOnly = true,
    this.phraseLoopTimerSeconds = 0,
    this.phraseLoopMode = 'inmediato',
    this.customNickname = '',
    required this.updatedAt,
  });

  /// Factory for authentic default configuration of Boss GT-1B Bass
  factory DeviceConfig.defaultGt1b() {
    return DeviceConfig(
      deviceId: 'boss_gt1b',
      deviceName: 'Boss GT-1B (Bass)',
      lastConnectionType: 'usbOtg',
      autoReconnect: true,
      lastPatchIndex: 0,
      quickPresets: const [],
      metronomeBpm: 120,
      metronomeTimeSignature: 4,
      metronomeVisualOnly: true,
      phraseLoopTimerSeconds: 0,
      phraseLoopMode: 'inmediato',
      customNickname: 'Boss GT-1B Principal',
      updatedAt: DateTime.now(),
    );
  }

  DeviceConfig copyWith({
    String? deviceId,
    String? deviceName,
    String? lastConnectionType,
    bool? autoReconnect,
    int? lastPatchIndex,
    List<QuickPreset>? quickPresets,
    int? metronomeBpm,
    int? metronomeTimeSignature,
    bool? metronomeVisualOnly,
    int? phraseLoopTimerSeconds,
    String? phraseLoopMode,
    String? customNickname,
    DateTime? updatedAt,
  }) {
    return DeviceConfig(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      lastConnectionType: lastConnectionType ?? this.lastConnectionType,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      lastPatchIndex: lastPatchIndex ?? this.lastPatchIndex,
      quickPresets: quickPresets ?? this.quickPresets,
      metronomeBpm: metronomeBpm ?? this.metronomeBpm,
      metronomeTimeSignature: metronomeTimeSignature ?? this.metronomeTimeSignature,
      metronomeVisualOnly: metronomeVisualOnly ?? this.metronomeVisualOnly,
      phraseLoopTimerSeconds: phraseLoopTimerSeconds ?? this.phraseLoopTimerSeconds,
      phraseLoopMode: phraseLoopMode ?? this.phraseLoopMode,
      customNickname: customNickname ?? this.customNickname,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'lastConnectionType': lastConnectionType,
        'autoReconnect': autoReconnect,
        'lastPatchIndex': lastPatchIndex,
        'quickPresets': quickPresets.map((p) => p.toJson()).toList(),
        'metronomeBpm': metronomeBpm,
        'metronomeTimeSignature': metronomeTimeSignature,
        'metronomeVisualOnly': metronomeVisualOnly,
        'phraseLoopTimerSeconds': phraseLoopTimerSeconds,
        'phraseLoopMode': phraseLoopMode,
        'customNickname': customNickname,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    final rawPresets = json['quickPresets'] as List<dynamic>? ?? [];
    final presets = rawPresets
        .map((p) => QuickPreset.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();

    return DeviceConfig(
      deviceId: json['deviceId'] as String? ?? 'boss_gt1b',
      deviceName: json['deviceName'] as String? ?? 'Boss GT-1B (Bass)',
      lastConnectionType: json['lastConnectionType'] as String? ?? 'usbOtg',
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      lastPatchIndex: json['lastPatchIndex'] as int? ?? 0,
      quickPresets: presets,
      metronomeBpm: json['metronomeBpm'] as int? ?? 120,
      metronomeTimeSignature: json['metronomeTimeSignature'] as int? ?? 4,
      metronomeVisualOnly: json['metronomeVisualOnly'] as bool? ?? true,
      phraseLoopTimerSeconds: json['phraseLoopTimerSeconds'] as int? ?? 0,
      phraseLoopMode: json['phraseLoopMode'] as String? ?? 'inmediato',
      customNickname: json['customNickname'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
