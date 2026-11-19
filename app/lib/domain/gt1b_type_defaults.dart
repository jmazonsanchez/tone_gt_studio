// Authentic GT-1B factory defaults for effect algorithms and types.
// When an effect type/algorithm is selected, these parameter profiles are applied.

class Gt1bTypeDefaults {
  static const Map<int, Map<String, int>> compDefaults = {
    0: {'comp_sustain': 50, 'comp_attack': 50, 'comp_tone': 50, 'comp_level': 60}, // BOSS COMP
    1: {'comp_sustain': 60, 'comp_attack': 40, 'comp_tone': 65, 'comp_level': 55}, // HI-BAND
    2: {'comp_sustain': 30, 'comp_attack': 70, 'comp_tone': 50, 'comp_level': 65}, // LIGHT
    3: {'comp_sustain': 70, 'comp_attack': 30, 'comp_tone': 45, 'comp_level': 50}, // D-COMP
    4: {'comp_sustain': 65, 'comp_attack': 45, 'comp_tone': 55, 'comp_level': 55}, // ORANGE
    5: {'comp_sustain': 55, 'comp_attack': 35, 'comp_tone': 40, 'comp_level': 60}, // FAT
    6: {'comp_sustain': 40, 'comp_attack': 60, 'comp_tone': 50, 'comp_level': 55}, // MILD
    7: {'comp_sustain': 50, 'comp_attack': 50, 'comp_tone': 50, 'comp_level': 50}, // STEREO COMP
  };

  static const Map<int, Map<String, int>> odDefaults = {
    0: {'od_drive': 25, 'od_bottom': 50, 'od_tone': 50, 'od_level': 70, 'od_direct': 30}, // BOOSTER
    1: {'od_drive': 40, 'od_bottom': 55, 'od_tone': 50, 'od_level': 60, 'od_direct': 20}, // NATURAL
    2: {'od_drive': 50, 'od_bottom': 50, 'od_tone': 50, 'od_level': 50, 'od_direct': 0},  // BASS OD
    3: {'od_drive': 45, 'od_bottom': 60, 'od_tone': 48, 'od_level': 55, 'od_direct': 15}, // BLUES OD
    4: {'od_drive': 65, 'od_bottom': 50, 'od_tone': 55, 'od_level': 50, 'od_direct': 0},  // BASS DS
    5: {'od_drive': 70, 'od_bottom': 45, 'od_tone': 60, 'od_level': 45, 'od_direct': 0},  // GUV DS
    6: {'od_drive': 75, 'od_bottom': 60, 'od_tone': 65, 'od_level': 50, 'od_direct': 0},  // BASS MT
    7: {'od_drive': 80, 'od_bottom': 65, 'od_tone': 70, 'od_level': 45, 'od_direct': 0},  // METAL ZONE
    8: {'od_drive': 85, 'od_bottom': 70, 'od_tone': 40, 'od_level': 50, 'od_direct': 10}, // BASS FUZZ
    9: {'od_drive': 90, 'od_bottom': 75, 'od_tone': 35, 'od_level': 50, 'od_direct': 0},  // MUFF FUZZ
    10: {'od_drive': 55, 'od_bottom': 40, 'od_tone': 65, 'od_level': 55, 'od_direct': 30}, // HiBND DRV
    11: {'od_drive': 60, 'od_bottom': 50, 'od_tone': 50, 'od_level': 50, 'od_direct': 0},  // AB-DIST
    12: {'od_drive': 50, 'od_bottom': 55, 'od_tone': 52, 'od_level': 55, 'od_direct': 20}, // BASS DRV
    13: {'od_drive': 35, 'od_bottom': 60, 'od_tone': 55, 'od_level': 60, 'od_direct': 25}, // BASS DI
    14: {'od_drive': 0, 'od_bottom': 50, 'od_tone': 50, 'od_level': 50, 'od_direct': 0},   // PARA.EQ
    15: {'od_drive': 50, 'od_bottom': 50, 'od_tone': 50, 'od_level': 50, 'od_direct': 0},  // CUSTOM
    16: {'od_drive': 45, 'od_bottom': 45, 'od_tone': 50, 'od_level': 55, 'od_direct': 0},  // OD-1
    17: {'od_drive': 55, 'od_bottom': 45, 'od_tone': 55, 'od_level': 50, 'od_direct': 0},  // OD-2
    18: {'od_drive': 40, 'od_bottom': 50, 'od_tone': 52, 'od_level': 58, 'od_direct': 10}, // CRUNCH
    19: {'od_drive': 65, 'od_bottom': 40, 'od_tone': 55, 'od_level': 50, 'od_direct': 0},  // DS-1
    20: {'od_drive': 75, 'od_bottom': 45, 'od_tone': 58, 'od_level': 50, 'od_direct': 0},  // DS-2
    21: {'od_drive': 80, 'od_bottom': 55, 'od_tone': 65, 'od_level': 48, 'od_direct': 0},  // METAL1
    22: {'od_drive': 85, 'od_bottom': 60, 'od_tone': 70, 'od_level': 45, 'od_direct': 0},  // METAL2
    23: {'od_drive': 88, 'od_bottom': 65, 'od_tone': 45, 'od_level': 50, 'od_direct': 0},  // FUZZ
  };

  static const Map<int, Map<String, int>> preampDefaults = {
    0: {'amp_gain': 40, 'amp_t_comp': 10, 'amp_bass': 50, 'amp_middle': 50, 'amp_treble': 50, 'amp_presence': 50, 'amp_level': 60, 'amp_bright': 0}, // SUPER FLAT
    1: {'amp_gain': 55, 'amp_t_comp': 25, 'amp_bass': 60, 'amp_middle': 45, 'amp_treble': 45, 'amp_presence': 40, 'amp_level': 55, 'amp_bright': 0}, // FLIP TOP
    2: {'amp_gain': 50, 'amp_t_comp': 20, 'amp_bass': 55, 'amp_middle': 55, 'amp_treble': 50, 'amp_presence': 50, 'amp_level': 58, 'amp_bright': 1}, // B MAN
    3: {'amp_gain': 45, 'amp_t_comp': 15, 'amp_bass': 50, 'amp_middle': 60, 'amp_treble': 55, 'amp_presence': 50, 'amp_level': 60, 'amp_bright': 0}, // CONCERT
    4: {'amp_gain': 60, 'amp_t_comp': 30, 'amp_bass': 65, 'amp_middle': 40, 'amp_treble': 60, 'amp_presence': 55, 'amp_level': 55, 'amp_bright': 1}, // BASS 360
    5: {'amp_gain': 45, 'amp_t_comp': 20, 'amp_bass': 50, 'amp_middle': 50, 'amp_treble': 55, 'amp_presence': 50, 'amp_level': 60, 'amp_bright': 0}, // SESSION
    6: {'amp_gain': 35, 'amp_t_comp': 10, 'amp_bass': 45, 'amp_middle': 55, 'amp_treble': 65, 'amp_presence': 60, 'amp_level': 65, 'amp_bright': 1}, // AC BASS
    7: {'amp_gain': 55, 'amp_t_comp': 20, 'amp_bass': 55, 'amp_middle': 50, 'amp_treble': 65, 'amp_presence': 60, 'amp_level': 58, 'amp_bright': 1}, // GK BASS
    8: {'amp_gain': 50, 'amp_t_comp': 25, 'amp_bass': 50, 'amp_middle': 65, 'amp_treble': 50, 'amp_presence': 45, 'amp_level': 60, 'amp_bright': 0}, // MARK
    9: {'amp_gain': 30, 'amp_t_comp': 10, 'amp_bass': 50, 'amp_middle': 50, 'amp_treble': 55, 'amp_presence': 50, 'amp_level': 65, 'amp_bright': 1}, // CLEAN
    10: {'amp_gain': 60, 'amp_t_comp': 20, 'amp_bass': 50, 'amp_middle': 55, 'amp_treble': 55, 'amp_presence': 55, 'amp_level': 55, 'amp_bright': 0}, // CRUNCH
    11: {'amp_gain': 75, 'amp_t_comp': 25, 'amp_bass': 55, 'amp_middle': 50, 'amp_treble': 60, 'amp_presence': 60, 'amp_level': 50, 'amp_bright': 0}, // DRIVE
    12: {'amp_gain': 85, 'amp_t_comp': 30, 'amp_bass': 60, 'amp_middle': 45, 'amp_treble': 65, 'amp_presence': 65, 'amp_level': 48, 'amp_bright': 0}, // METAL
  };

  static const Map<int, Map<String, int>> delayDefaults = {
    0: {'dly_time': 350, 'dly_feedback': 25, 'dly_level': 50, 'dly_direct': 100}, // STANDARD
    1: {'dly_time': 375, 'dly_feedback': 30, 'dly_level': 50, 'dly_direct': 100}, // PAN
    2: {'dly_time': 450, 'dly_feedback': 35, 'dly_level': 55, 'dly_direct': 80},  // REVERSE
    3: {'dly_time': 300, 'dly_feedback': 30, 'dly_level': 45, 'dly_direct': 100}, // ANALOG
    4: {'dly_time': 320, 'dly_feedback': 28, 'dly_level': 48, 'dly_direct': 100}, // TAPE
    5: {'dly_time': 400, 'dly_feedback': 40, 'dly_level': 60, 'dly_direct': 90},  // WARP
    6: {'dly_time': 380, 'dly_feedback': 32, 'dly_level': 50, 'dly_direct': 100}, // MODULATE
  };

  static const Map<int, Map<String, int>> chorusDefaults = {
    0: {'cho_rate': 35, 'cho_depth': 50, 'cho_level': 50, 'cho_direct': 100}, // MONO
    1: {'cho_rate': 42, 'cho_depth': 55, 'cho_level': 55, 'cho_direct': 100}, // STEREO
    2: {'cho_rate': 48, 'cho_depth': 60, 'cho_level': 60, 'cho_direct': 100}, // 2x2
  };

  static const Map<int, Map<String, int>> reverbDefaults = {
    0: {'rev_time': 15, 'rev_density': 4, 'rev_level': 35, 'rev_direct': 100}, // AMBIENCE
    1: {'rev_time': 25, 'rev_density': 5, 'rev_level': 40, 'rev_direct': 100}, // ROOM
    2: {'rev_time': 35, 'rev_density': 6, 'rev_level': 45, 'rev_direct': 100}, // HALL 1
    3: {'rev_time': 45, 'rev_density': 7, 'rev_level': 50, 'rev_direct': 100}, // HALL 2
    4: {'rev_time': 30, 'rev_density': 6, 'rev_level': 42, 'rev_direct': 100}, // PLATE
    5: {'rev_time': 20, 'rev_density': 4, 'rev_level': 38, 'rev_direct': 100}, // SPRING
    6: {'rev_time': 40, 'rev_density': 6, 'rev_level': 48, 'rev_direct': 100}, // MODULATE
  };

  static const Map<int, Map<String, int>> wahDefaults = {
    0: {'wah_position': 50, 'wah_min': 0, 'wah_max': 100, 'wah_level': 100}, // BASS WAH
    1: {'wah_position': 50, 'wah_min': 10, 'wah_max': 95, 'wah_level': 100}, // CRY WAH
    2: {'wah_position': 50, 'wah_min': 15, 'wah_max': 90, 'wah_level': 95},  // VO WAH
    3: {'wah_position': 50, 'wah_min': 0, 'wah_max': 85, 'wah_level': 100},  // FAT WAH
    4: {'wah_position': 50, 'wah_min': 20, 'wah_max': 100, 'wah_level': 100}, // LIGHT WAH
    5: {'wah_position': 50, 'wah_min': 0, 'wah_max': 90, 'wah_level': 100},  // 7STRING WAH
    6: {'wah_position': 50, 'wah_min': 5, 'wah_max': 100, 'wah_level': 90},  // RESO WAH
  };

  /// Returns parameter defaults for a given type selector parameter and type index.
  static Map<String, int>? getDefaults(String typeParamId, int typeIndex) {
    switch (typeParamId) {
      case 'comp_type':
        return compDefaults[typeIndex];
      case 'od_type':
        return odDefaults[typeIndex];
      case 'amp_type':
        return preampDefaults[typeIndex];
      case 'dly_type':
        return delayDefaults[typeIndex];
      case 'cho_mode':
        return chorusDefaults[typeIndex];
      case 'rev_type':
        return reverbDefaults[typeIndex];
      case 'wah_type':
        return wahDefaults[typeIndex];
      default:
        return null;
    }
  }
}
