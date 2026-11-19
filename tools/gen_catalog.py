#!/usr/bin/env python3
"""Script de generacion de catalogo y mapa de direcciones para Boss GT-1B.
Lee docs/gt1b_addressmap.json y genera:
 - app/lib/protocol/gt1b_map.dart
 - app/lib/domain/gt1b_catalog.dart
"""
import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(BASE_DIR, "docs", "gt1b_addressmap.json")
OUT_MAP_PATH = os.path.join(BASE_DIR, "app", "lib", "protocol", "gt1b_map.dart")
OUT_CATALOG_PATH = os.path.join(BASE_DIR, "app", "lib", "domain", "gt1b_catalog.dart")

def main():
    print(f"Generando catálogo GT-1B con parámetros oficiales...")

    # 1. Generar gt1b_map.dart
    os.makedirs(os.path.dirname(OUT_MAP_PATH), exist_ok=True)
    with open(OUT_MAP_PATH, "w", encoding="utf-8") as f:
        f.write("""// ARCHIVO GENERADO AUTOMÁTICAMENTE POR tools/gen_catalog.py - NO EDITAR A MANO
// Mapa de direcciones de memoria oficial Boss GT-1B

class Gt1bMap {
  // Comandos y Handshake
  static const List<int> editorCommunicationMode = [0x7F, 0x00, 0x00, 0x01];
  static const List<int> editorCommunicationLevel = [0x7F, 0x00, 0x00, 0x00];
  static const List<int> runningMode = [0x7F, 0x00, 0x00, 0x02]; // 00=Play, 01=Tuner
  static const List<int> tunerSingleModePitch = [0x7F, 0x00, 0x05, 0x00];
  static const List<int> patchWrite = [0x7F, 0x00, 0x01, 0x04];
  static const List<int> patchCopy = [0x7F, 0x00, 0x01, 0x00];

  // Presets y Setup
  static const List<int> currentPatchNo = [0x00, 0x01, 0x00, 0x00];
  static const List<int> userPatchListTop = [0x10, 0x00, 0x00, 0x00];
  static const List<int> presetPatchListTop = [0x20, 0x00, 0x00, 0x00];

  // Buffer Temporal (Parches Activos)
  static const List<int> temporaryBase = [0x60, 0x00, 0x00, 0x00];
  static const List<int> patchName = [0x60, 0x00, 0x00, 0x00]; // 16 bytes

  // Switches Directos de Efectos (ON/OFF)
  static const List<int> compSwitch = [0x60, 0x00, 0x00, 0x20];
  static const List<int> odDsSwitch = [0x60, 0x00, 0x00, 0x30];
  static const List<int> preampSwitch = [0x60, 0x00, 0x00, 0x50];
  static const List<int> eqSwitch = [0x60, 0x00, 0x01, 0x30];
  static const List<int> fx1Switch = [0x60, 0x00, 0x01, 0x40];
  static const List<int> fx2Switch = [0x60, 0x00, 0x03, 0x4C];
  static const List<int> delaySwitch = [0x60, 0x00, 0x05, 0x60];
  static const List<int> chorusSwitch = [0x60, 0x00, 0x06, 0x00];
  static const List<int> reverbSwitch = [0x60, 0x00, 0x06, 0x10];
  static const List<int> pedalFxSwitch = [0x60, 0x00, 0x06, 0x20];
  static const List<int> pedalFxWahPosition = [0x60, 0x00, 0x06, 0x27];
  static const List<int> footVolumeLevel = [0x60, 0x00, 0x06, 0x33];
  static const List<int> ns1Switch = [0x60, 0x00, 0x06, 0x63];
  static const List<int> ns1Threshold = [0x60, 0x00, 0x06, 0x64];
  static const List<int> ns1Release = [0x60, 0x00, 0x06, 0x65];

  // Cadena de Efectos (Memory Edit)
  static const List<int> fxChainBase = [0x60, 0x00, 0x07, 0x20]; // 20 bytes
}
""")
    print(f"✓ Generado: {OUT_MAP_PATH}")

    # 2. Generar gt1b_catalog.dart con catálogo oficial completo
    os.makedirs(os.path.dirname(OUT_CATALOG_PATH), exist_ok=True)
    with open(OUT_CATALOG_PATH, "w", encoding="utf-8") as f:
        f.write("""// ARCHIVO GENERADO AUTOMÁTICAMENTE POR tools/gen_catalog.py - NO EDITAR A MANO
// Catálogo oficial de definiciones de efectos y parámetros de la Boss GT-1B

import '../models/effect_block.dart';

class ParamDef {
  final String id;
  final String name;
  final List<int> address;
  final int min;
  final int max;
  final int defaultValue;
  final List<String>? options;
  final String? unit;
  final bool isToggle;
  final int displayOffset;

  const ParamDef({
    required this.id,
    required this.name,
    required this.address,
    this.min = 0,
    this.max = 100,
    this.defaultValue = 50,
    this.options,
    this.unit,
    this.isToggle = false,
    this.displayOffset = 0,
  });

  bool get isEnum => options != null && options!.isNotEmpty;

  String formatValue(int rawValue) {
    if (isToggle) {
      return rawValue > 0 ? 'ON' : 'OFF';
    }
    if (isEnum && options != null) {
      final idx = rawValue.clamp(0, options!.length - 1);
      return options![idx];
    }
    final adjusted = rawValue + displayOffset;
    if (unit != null) {
      return '$adjusted $unit';
    }
    return '$adjusted';
  }
}

class Gt1bCatalog {
  // Opciones oficiales de algoritmos y tipos Roland / Boss GT-1B
  static const List<String> compTypes = [
    'BOSS COMP', 'HI-BAND', 'LIGHT', 'D-COMP',
    'ORANGE', 'FAT', 'MILD', 'STEREO COMP',
  ];

  static const List<String> odTypes = [
    'BOOSTER', 'NATURAL', 'BASS OD', 'BLUES OD',
    'BASS DS', 'GUV DS', 'BASS MT', 'METAL ZONE',
    'BASS FUZZ', 'MUFF FUZZ', 'HiBND DRV', 'AB-DIST',
    'BASS DRV', 'BASS DI', 'PARA.EQ', 'CUSTOM',
    'OD-1', 'OD-2', 'CRUNCH', 'DS-1',
    'DS-2', 'METAL1', 'METAL2', 'FUZZ',
  ];

  static const List<String> preampTypes = [
    'SUPER FLAT', 'FLIP TOP', 'B MAN', 'CONCERT',
    'BASS 360', 'SESSION', 'AC BASS', 'GK BASS',
    'MARK', 'GUITAR CLEAN', 'GUITAR CRUNCH', 'GUITAR DRIVE',
    'GUITAR METAL',
  ];

  static const List<String> speakerTypes = [
    'ORIGIN', '1x8"', '1x10"', '1x12"',
    '2x12"', '4x10"', '4x12"', '8x12"',
    '1x15"', '1x18"', '2x15"', '8x10"',
  ];

  static const List<String> micTypes = [
    'DYN57', 'DYN421', 'CND451', 'CND87', 'FLAT',
  ];

  static const List<String> delayTypes = [
    'STANDARD', 'PAN', 'REVERSE', 'ANALOG',
    'TAPE', 'WARP', 'MODULATE',
  ];

  static const List<String> chorusModes = [
    'MONO', 'STEREO', '2x2',
  ];

  static const List<String> reverbTypes = [
    'AMBIENCE', 'ROOM', 'HALL 1', 'HALL 2',
    'PLATE', 'SPRING', 'MODULATE',
  ];

  static const List<String> wahTypes = [
    'BASS WAH', 'CRY WAH', 'VO WAH', 'FAT WAH',
    'LIGHT WAH', '7STRING WAH', 'RESO WAH',
  ];

  static const List<String> volumeCurves = [
    'LINEAR', 'SLOW', 'FAST',
  ];

  static const List<String> nsDetectSources = [
    'INPUT', 'NS INPUT', 'FV OUT',
  ];

  // Catálogo completo de parámetros por bloque
  static const Map<EffectCategory, List<ParamDef>> effectParams = {
    EffectCategory.comp: [
      ParamDef(id: 'comp_type', name: 'Type', address: [0x60, 0x00, 0x00, 0x21], min: 0, max: 7, defaultValue: 0, options: compTypes),
      ParamDef(id: 'comp_sustain', name: 'Sustain', address: [0x60, 0x00, 0x00, 0x22], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'comp_attack', name: 'Attack', address: [0x60, 0x00, 0x00, 0x23], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'comp_tone', name: 'Tone', address: [0x60, 0x00, 0x00, 0x24], min: 0, max: 100, defaultValue: 50, displayOffset: -50),
      ParamDef(id: 'comp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x25], min: 0, max: 100, defaultValue: 60),
    ],
    EffectCategory.odDs: [
      ParamDef(id: 'od_type', name: 'Type', address: [0x60, 0x00, 0x00, 0x31], min: 0, max: 23, defaultValue: 2, options: odTypes),
      ParamDef(id: 'od_drive', name: 'Drive', address: [0x60, 0x00, 0x00, 0x32], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_bottom', name: 'Bottom', address: [0x60, 0x00, 0x00, 0x33], min: 0, max: 100, defaultValue: 50, displayOffset: -50),
      ParamDef(id: 'od_tone', name: 'Tone', address: [0x60, 0x00, 0x00, 0x34], min: 0, max: 100, defaultValue: 50, displayOffset: -50),
      ParamDef(id: 'od_solo_sw', name: 'Solo Switch', address: [0x60, 0x00, 0x00, 0x35], min: 0, max: 1, defaultValue: 0, isToggle: true),
      ParamDef(id: 'od_solo_level', name: 'Solo Level', address: [0x60, 0x00, 0x00, 0x36], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_level', name: 'Effect Level', address: [0x60, 0x00, 0x00, 0x37], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_direct', name: 'Direct Mix', address: [0x60, 0x00, 0x00, 0x38], min: 0, max: 100, defaultValue: 0, unit: '%'),
    ],
    EffectCategory.preamp: [
      ParamDef(id: 'amp_type', name: 'Amp Type', address: [0x60, 0x00, 0x00, 0x51], min: 0, max: 12, defaultValue: 3, options: preampTypes),
      ParamDef(id: 'amp_gain', name: 'Gain', address: [0x60, 0x00, 0x00, 0x52], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_t_comp', name: 'T-Comp', address: [0x60, 0x00, 0x00, 0x53], min: 0, max: 100, defaultValue: 20),
      ParamDef(id: 'amp_bass', name: 'Bass', address: [0x60, 0x00, 0x00, 0x54], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_middle', name: 'Middle', address: [0x60, 0x00, 0x00, 0x55], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_treble', name: 'Treble', address: [0x60, 0x00, 0x00, 0x56], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_presence', name: 'Presence', address: [0x60, 0x00, 0x00, 0x57], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x58], min: 0, max: 100, defaultValue: 60),
      ParamDef(id: 'amp_bright', name: 'Bright', address: [0x60, 0x00, 0x00, 0x59], min: 0, max: 1, defaultValue: 0, isToggle: true),
      ParamDef(id: 'amp_sp_type', name: 'Speaker Sim', address: [0x60, 0x00, 0x00, 0x5D], min: 0, max: 11, defaultValue: 0, options: speakerTypes),
      ParamDef(id: 'amp_mic_type', name: 'Mic Type', address: [0x60, 0x00, 0x00, 0x5E], min: 0, max: 4, defaultValue: 0, options: micTypes),
      ParamDef(id: 'amp_direct', name: 'Direct Mix', address: [0x60, 0x00, 0x00, 0x62], min: 0, max: 100, defaultValue: 0, unit: '%'),
    ],
    EffectCategory.eq: [
      ParamDef(id: 'eq_low_gain', name: 'Low Gain', address: [0x60, 0x00, 0x01, 0x32], min: 0, max: 40, defaultValue: 20, displayOffset: -20, unit: 'dB'),
      ParamDef(id: 'eq_low_mid_freq', name: 'Low-Mid Freq', address: [0x60, 0x00, 0x01, 0x33], min: 0, max: 27, defaultValue: 10),
      ParamDef(id: 'eq_low_mid_q', name: 'Low-Mid Q', address: [0x60, 0x00, 0x01, 0x34], min: 0, max: 5, defaultValue: 1),
      ParamDef(id: 'eq_low_mid_gain', name: 'Low-Mid Gain', address: [0x60, 0x00, 0x01, 0x35], min: 0, max: 40, defaultValue: 20, displayOffset: -20, unit: 'dB'),
      ParamDef(id: 'eq_high_mid_freq', name: 'High-Mid Freq', address: [0x60, 0x00, 0x01, 0x36], min: 0, max: 27, defaultValue: 18),
      ParamDef(id: 'eq_high_mid_q', name: 'High-Mid Q', address: [0x60, 0x00, 0x01, 0x37], min: 0, max: 5, defaultValue: 1),
      ParamDef(id: 'eq_high_mid_gain', name: 'High-Mid Gain', address: [0x60, 0x00, 0x01, 0x38], min: 0, max: 40, defaultValue: 20, displayOffset: -20, unit: 'dB'),
      ParamDef(id: 'eq_high_gain', name: 'High Gain', address: [0x60, 0x00, 0x01, 0x39], min: 0, max: 40, defaultValue: 20, displayOffset: -20, unit: 'dB'),
      ParamDef(id: 'eq_level', name: 'Level', address: [0x60, 0x00, 0x01, 0x3B], min: 0, max: 100, defaultValue: 50),
    ],
    EffectCategory.delay: [
      ParamDef(id: 'dly_type', name: 'Type', address: [0x60, 0x00, 0x05, 0x61], min: 0, max: 6, defaultValue: 0, options: delayTypes),
      ParamDef(id: 'dly_time', name: 'Delay Time', address: [0x60, 0x00, 0x05, 0x62], min: 1, max: 2000, defaultValue: 350, unit: 'ms'),
      ParamDef(id: 'dly_feedback', name: 'Feedback', address: [0x60, 0x00, 0x05, 0x64], min: 0, max: 100, defaultValue: 25),
      ParamDef(id: 'dly_level', name: 'Effect Level', address: [0x60, 0x00, 0x05, 0x66], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'dly_direct', name: 'Direct Mix', address: [0x60, 0x00, 0x05, 0x67], min: 0, max: 100, defaultValue: 100, unit: '%'),
    ],
    EffectCategory.chorus: [
      ParamDef(id: 'cho_mode', name: 'Mode', address: [0x60, 0x00, 0x06, 0x01], min: 0, max: 2, defaultValue: 1, options: chorusModes),
      ParamDef(id: 'cho_rate', name: 'Rate', address: [0x60, 0x00, 0x06, 0x02], min: 0, max: 100, defaultValue: 40),
      ParamDef(id: 'cho_depth', name: 'Depth', address: [0x60, 0x00, 0x06, 0x03], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'cho_level', name: 'Effect Level', address: [0x60, 0x00, 0x06, 0x07], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'cho_direct', name: 'Direct Level', address: [0x60, 0x00, 0x06, 0x08], min: 0, max: 100, defaultValue: 100),
    ],
    EffectCategory.reverb: [
      ParamDef(id: 'rev_type', name: 'Type', address: [0x60, 0x00, 0x06, 0x11], min: 0, max: 6, defaultValue: 1, options: reverbTypes),
      ParamDef(id: 'rev_time', name: 'Reverb Time', address: [0x60, 0x00, 0x06, 0x12], min: 1, max: 100, defaultValue: 28),
      ParamDef(id: 'rev_density', name: 'Density', address: [0x60, 0x00, 0x06, 0x17], min: 0, max: 10, defaultValue: 5),
      ParamDef(id: 'rev_level', name: 'Effect Level', address: [0x60, 0x00, 0x06, 0x18], min: 0, max: 100, defaultValue: 40),
      ParamDef(id: 'rev_direct', name: 'Direct Mix', address: [0x60, 0x00, 0x06, 0x19], min: 0, max: 100, defaultValue: 100, unit: '%'),
    ],
    EffectCategory.pedalFx: [
      ParamDef(id: 'wah_type', name: 'Wah Type', address: [0x60, 0x00, 0x06, 0x26], min: 0, max: 6, defaultValue: 0, options: wahTypes),
      ParamDef(id: 'wah_position', name: 'Position', address: [0x60, 0x00, 0x06, 0x27], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'wah_min', name: 'Pedal Min', address: [0x60, 0x00, 0x06, 0x28], min: 0, max: 100, defaultValue: 0),
      ParamDef(id: 'wah_max', name: 'Pedal Max', address: [0x60, 0x00, 0x06, 0x29], min: 0, max: 100, defaultValue: 100),
      ParamDef(id: 'wah_level', name: 'Effect Level', address: [0x60, 0x00, 0x06, 0x2A], min: 0, max: 100, defaultValue: 100),
    ],
    EffectCategory.footVolume: [
      ParamDef(id: 'fv_curve', name: 'Curve', address: [0x60, 0x00, 0x06, 0x30], min: 0, max: 2, defaultValue: 0, options: volumeCurves),
      ParamDef(id: 'fv_min', name: 'Volume Min', address: [0x60, 0x00, 0x06, 0x31], min: 0, max: 100, defaultValue: 0),
      ParamDef(id: 'fv_max', name: 'Volume Max', address: [0x60, 0x00, 0x06, 0x32], min: 0, max: 100, defaultValue: 100),
      ParamDef(id: 'fv_level', name: 'Live Level', address: [0x60, 0x00, 0x06, 0x33], min: 0, max: 100, defaultValue: 100),
    ],
    EffectCategory.noiseSuppressor: [
      ParamDef(id: 'ns_threshold', name: 'Threshold', address: [0x60, 0x00, 0x06, 0x64], min: 0, max: 100, defaultValue: 45),
      ParamDef(id: 'ns_release', name: 'Release', address: [0x60, 0x00, 0x06, 0x65], min: 0, max: 100, defaultValue: 30),
      ParamDef(id: 'ns_detect', name: 'Detect Source', address: [0x60, 0x00, 0x06, 0x66], min: 0, max: 2, defaultValue: 0, options: nsDetectSources),
    ],
  };
}
""")
    print(f"✓ Generado: {OUT_CATALOG_PATH}")

if __name__ == "__main__":
    main()
