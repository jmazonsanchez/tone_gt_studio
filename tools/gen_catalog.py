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

def parse_addr(addr_str):
    return [int(x, 16) for x in addr_str.split(",")]

def hex_list_str(byte_list):
    return "[" + ", ".join(f"0x{b:02X}" for b in byte_list) + "]"

def main():
    print(f"Leyendo mapa de direcciones desde {JSON_PATH}...")
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    temp_items = data.get("temporary", [])
    print(f"Total parámetros temporales: {len(temp_items)}")

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

    # 2. Generar gt1b_catalog.dart
    os.makedirs(os.path.dirname(OUT_CATALOG_PATH), exist_ok=True)
    with open(OUT_CATALOG_PATH, "w", encoding="utf-8") as f:
        f.write("""// ARCHIVO GENERADO AUTOMÁTICAMENTE POR tools/gen_catalog.py - NO EDITAR A MANO
// Catálogo de definiciones de efectos y parámetros de la Boss GT-1B

import '../models/effect_block.dart';

class ParamDef {
  final String id;
  final String name;
  final List<int> address;
  final int min;
  final int max;
  final int defaultValue;

  const ParamDef({
    required this.id,
    required this.name,
    required this.address,
    this.min = 0,
    this.max = 100,
    this.defaultValue = 50,
  });
}

class Gt1bCatalog {
  // Parámetros principales por bloque de efecto
  static const Map<EffectCategory, List<ParamDef>> effectParams = {
    EffectCategory.comp: [
      ParamDef(id: 'comp_type', name: 'Type', address: [0x60, 0x00, 0x00, 0x21], min: 0, max: 7, defaultValue: 0),
      ParamDef(id: 'comp_sustain', name: 'Sustain', address: [0x60, 0x00, 0x00, 0x22], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'comp_attack', name: 'Attack', address: [0x60, 0x00, 0x00, 0x23], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'comp_tone', name: 'Tone', address: [0x60, 0x00, 0x00, 0x24], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'comp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x25], min: 0, max: 100, defaultValue: 60),
    ],
    EffectCategory.odDs: [
      ParamDef(id: 'od_type', name: 'Type', address: [0x60, 0x00, 0x00, 0x31], min: 0, max: 23, defaultValue: 0),
      ParamDef(id: 'od_drive', name: 'Drive', address: [0x60, 0x00, 0x00, 0x32], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_bottom', name: 'Bottom', address: [0x60, 0x00, 0x00, 0x33], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_tone', name: 'Tone', address: [0x60, 0x00, 0x00, 0x34], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x37], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'od_direct', name: 'Direct Mix', address: [0x60, 0x00, 0x00, 0x38], min: 0, max: 100, defaultValue: 0),
    ],
    EffectCategory.preamp: [
      ParamDef(id: 'amp_type', name: 'Type', address: [0x60, 0x00, 0x00, 0x51], min: 0, max: 15, defaultValue: 0),
      ParamDef(id: 'amp_gain', name: 'Gain', address: [0x60, 0x00, 0x00, 0x52], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_bass', name: 'Bass', address: [0x60, 0x00, 0x00, 0x54], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_middle', name: 'Middle', address: [0x60, 0x00, 0x00, 0x55], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_treble', name: 'Treble', address: [0x60, 0x00, 0x00, 0x56], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_presence', name: 'Presence', address: [0x60, 0x00, 0x00, 0x57], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'amp_level', name: 'Level', address: [0x60, 0x00, 0x00, 0x58], min: 0, max: 100, defaultValue: 60),
    ],
    EffectCategory.eq: [
      ParamDef(id: 'eq_low_gain', name: 'Low Gain', address: [0x60, 0x00, 0x01, 0x32], min: 0, max: 40, defaultValue: 20),
      ParamDef(id: 'eq_low_mid_gain', name: 'Low-Mid Gain', address: [0x60, 0x00, 0x01, 0x35], min: 0, max: 40, defaultValue: 20),
      ParamDef(id: 'eq_high_mid_gain', name: 'High-Mid Gain', address: [0x60, 0x00, 0x01, 0x38], min: 0, max: 40, defaultValue: 20),
      ParamDef(id: 'eq_high_gain', name: 'High Gain', address: [0x60, 0x00, 0x01, 0x39], min: 0, max: 40, defaultValue: 20),
      ParamDef(id: 'eq_level', name: 'Level', address: [0x60, 0x00, 0x01, 0x3B], min: 0, max: 100, defaultValue: 50),
    ],
    EffectCategory.delay: [
      ParamDef(id: 'dly_time', name: 'Time', address: [0x60, 0x00, 0x05, 0x62], min: 1, max: 2000, defaultValue: 350),
      ParamDef(id: 'dly_feedback', name: 'Feedback', address: [0x60, 0x00, 0x05, 0x64], min: 0, max: 100, defaultValue: 25),
      ParamDef(id: 'dly_level', name: 'Effect Level', address: [0x60, 0x00, 0x05, 0x66], min: 0, max: 100, defaultValue: 50),
    ],
    EffectCategory.chorus: [
      ParamDef(id: 'cho_rate', name: 'Rate', address: [0x60, 0x00, 0x06, 0x02], min: 0, max: 100, defaultValue: 40),
      ParamDef(id: 'cho_depth', name: 'Depth', address: [0x60, 0x00, 0x06, 0x03], min: 0, max: 100, defaultValue: 50),
      ParamDef(id: 'cho_level', name: 'Effect Level', address: [0x60, 0x00, 0x06, 0x07], min: 0, max: 100, defaultValue: 50),
    ],
    EffectCategory.reverb: [
      ParamDef(id: 'rev_time', name: 'Time', address: [0x60, 0x00, 0x06, 0x12], min: 1, max: 100, defaultValue: 28),
      ParamDef(id: 'rev_level', name: 'Effect Level', address: [0x60, 0x00, 0x06, 0x18], min: 0, max: 100, defaultValue: 40),
    ],
    EffectCategory.pedalFx: [
      ParamDef(id: 'wah_position', name: 'Position', address: [0x60, 0x00, 0x06, 0x27], min: 0, max: 100, defaultValue: 50),
    ],
    EffectCategory.footVolume: [
      ParamDef(id: 'fv_level', name: 'Volume Level', address: [0x60, 0x00, 0x06, 0x33], min: 0, max: 100, defaultValue: 100),
    ],
    EffectCategory.noiseSuppressor: [
      ParamDef(id: 'ns_threshold', name: 'Threshold', address: [0x60, 0x00, 0x06, 0x64], min: 0, max: 100, defaultValue: 45),
      ParamDef(id: 'ns_release', name: 'Release', address: [0x60, 0x00, 0x06, 0x65], min: 0, max: 100, defaultValue: 30),
    ],
  };
}
""")
    print(f"✓ Generado: {OUT_CATALOG_PATH}")

if __name__ == "__main__":
    main()
