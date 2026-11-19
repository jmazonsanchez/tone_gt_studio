import '../models/effect_block.dart';
import '../models/effect_parameter.dart';

/// Authentic Roland / Boss GT-1B FX1 and FX2 algorithm types and parameter builder.
class Gt1bFxAlgorithms {
  // Official GT-1B FX Algorithm Types (0..35)
  static const List<String> algorithmNames = [
    'SUB OD/DS', 'T.WAH', 'AUTO WAH', 'SUB WAH', 'COMPRESSOR',
    'LIMITER', 'GRAPHIC EQ', 'PARAMETRIC EQ', 'TONE MODIFY', 'BASS SIM',
    'SLOW GEAR', 'DEFRETTER', 'BASS SYNTH', 'SITAR SIM', 'OCTAVE',
    'PITCH SHIFTER', 'HARMONIST', 'SOUND HOLD', 'AC.PROCESSOR', 'PHASER',
    'FLANGER', 'TREMOLO', 'ROTARY', 'UNI-V', 'PAN',
    'SLICER', 'VIBRATO', 'RING MOD', 'HUMANIZER', '2x2 CHORUS',
    'SUB DELAY', 'AC.GUITAR SIM', 'ROTARY 2', 'OVERTONE', 'FEEDBACKER', 'CHORUS',
  ];

  static const List<String> octaveRanges = ['-2 OCT', '-1 OCT'];
  static const List<String> wahModes = ['LPF', 'BPF'];
  static const List<String> polarModes = ['DOWN', 'UP'];
  static const List<String> waveTypes = ['SAW', 'SQUARE'];

  /// Generates the list of parameters for a specific algorithm in FX1 or FX2.
  static List<EffectParameter> getParametersFor(
    EffectCategory category,
    int algorithmIndex,
  ) {
    final isFx1 = category == EffectCategory.fx1;
    final prefix = isFx1 ? 'fx1' : 'fx2';
    final typeAddr = isFx1 ? [0x60, 0x00, 0x01, 0x41] : [0x60, 0x00, 0x03, 0x4D];
    final safeIndex = algorithmIndex.clamp(0, algorithmNames.length - 1);

    // Primary Type Selector Parameter
    final typeParam = EffectParameter(
      id: '${prefix}_type',
      name: 'FX Type',
      address: typeAddr,
      min: 0,
      max: algorithmNames.length - 1,
      options: algorithmNames,
      value: safeIndex,
    );

    final params = <EffectParameter>[typeParam];

    switch (safeIndex) {
      case 0: params.addAll(_buildSubOdDs(isFx1, prefix)); break;
      case 1: params.addAll(_buildTWah(isFx1, prefix)); break;
      case 2: params.addAll(_buildAutoWah(isFx1, prefix)); break;
      case 3: params.addAll(_buildSubWah(isFx1, prefix)); break;
      case 4: params.addAll(_buildCompressor(isFx1, prefix)); break;
      case 5: params.addAll(_buildLimiter(isFx1, prefix)); break;
      case 8: params.addAll(_buildToneModify(isFx1, prefix)); break;
      case 9: params.addAll(_buildBassSim(isFx1, prefix)); break;
      case 10: params.addAll(_buildSlowGear(isFx1, prefix)); break;
      case 11: params.addAll(_buildDefretter(isFx1, prefix)); break;
      case 12: params.addAll(_buildBassSynth(isFx1, prefix)); break;
      case 14: params.addAll(_buildOctave(isFx1, prefix)); break;
      case 15: params.addAll(_buildPitchShifter(isFx1, prefix)); break;
      case 16: params.addAll(_buildHarmonist(isFx1, prefix)); break;
      case 19: params.addAll(_buildPhaser(isFx1, prefix)); break;
      case 20: params.addAll(_buildFlanger(isFx1, prefix)); break;
      case 21: params.addAll(_buildTremolo(isFx1, prefix)); break;
      case 22: params.addAll(_buildRotary(isFx1, prefix)); break;
      case 35: params.addAll(_buildChorus(isFx1, prefix)); break;
      default: params.addAll(_buildGeneric(isFx1, prefix)); break;
    }

    return params;
  }

  static List<EffectParameter> _buildOctave(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_oct_range', name: 'Range', address: isFx1 ? [0x60, 0x00, 0x02, 0x31] : [0x60, 0x00, 0x04, 0x3D], options: octaveRanges, value: 1),
    EffectParameter(id: '${prefix}_oct_level', name: 'Oct Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x32] : [0x60, 0x00, 0x04, 0x3E], value: 60),
    EffectParameter(id: '${prefix}_oct_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x02, 0x33] : [0x60, 0x00, 0x04, 0x3F], unit: '%', value: 80),
  ];

  static List<EffectParameter> _buildDefretter(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_df_tone', name: 'Tone', address: isFx1 ? [0x60, 0x00, 0x02, 0x18] : [0x60, 0x00, 0x04, 0x24], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_df_sens', name: 'Sens', address: isFx1 ? [0x60, 0x00, 0x02, 0x19] : [0x60, 0x00, 0x04, 0x25], value: 50),
    EffectParameter(id: '${prefix}_df_attack', name: 'Attack', address: isFx1 ? [0x60, 0x00, 0x02, 0x1A] : [0x60, 0x00, 0x04, 0x26], value: 50),
    EffectParameter(id: '${prefix}_df_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x02, 0x1B] : [0x60, 0x00, 0x04, 0x27], value: 60),
    EffectParameter(id: '${prefix}_df_reso', name: 'Reso', address: isFx1 ? [0x60, 0x00, 0x02, 0x1C] : [0x60, 0x00, 0x04, 0x28], value: 40),
    EffectParameter(id: '${prefix}_df_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x1D] : [0x60, 0x00, 0x04, 0x29], value: 50),
    EffectParameter(id: '${prefix}_df_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x02, 0x1E] : [0x60, 0x00, 0x04, 0x2A], unit: '%', value: 80),
  ];

  static List<EffectParameter> _buildAutoWah(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_aw_mode', name: 'Mode', address: isFx1 ? [0x60, 0x00, 0x01, 0x54] : [0x60, 0x00, 0x03, 0x60], options: wahModes, value: 0),
    EffectParameter(id: '${prefix}_aw_freq', name: 'Freq', address: isFx1 ? [0x60, 0x00, 0x01, 0x55] : [0x60, 0x00, 0x03, 0x61], value: 40),
    EffectParameter(id: '${prefix}_aw_peak', name: 'Peak', address: isFx1 ? [0x60, 0x00, 0x01, 0x56] : [0x60, 0x00, 0x03, 0x62], value: 50),
    EffectParameter(id: '${prefix}_aw_rate', name: 'Rate', address: isFx1 ? [0x60, 0x00, 0x01, 0x57] : [0x60, 0x00, 0x03, 0x63], value: 50),
    EffectParameter(id: '${prefix}_aw_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x01, 0x58] : [0x60, 0x00, 0x03, 0x64], value: 60),
    EffectParameter(id: '${prefix}_aw_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x5A] : [0x60, 0x00, 0x03, 0x66], value: 50),
    EffectParameter(id: '${prefix}_aw_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x01, 0x59] : [0x60, 0x00, 0x03, 0x65], unit: '%', value: 50),
  ];

  static List<EffectParameter> _buildTWah(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_tw_mode', name: 'Mode', address: isFx1 ? [0x60, 0x00, 0x01, 0x4C] : [0x60, 0x00, 0x03, 0x58], options: wahModes, value: 0),
    EffectParameter(id: '${prefix}_tw_polar', name: 'Polar', address: isFx1 ? [0x60, 0x00, 0x01, 0x4D] : [0x60, 0x00, 0x03, 0x59], options: polarModes, value: 1),
    EffectParameter(id: '${prefix}_tw_sens', name: 'Sens', address: isFx1 ? [0x60, 0x00, 0x01, 0x4E] : [0x60, 0x00, 0x03, 0x5A], value: 60),
    EffectParameter(id: '${prefix}_tw_peak', name: 'Peak', address: isFx1 ? [0x60, 0x00, 0x01, 0x50] : [0x60, 0x00, 0x03, 0x5C], value: 50),
    EffectParameter(id: '${prefix}_tw_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x52] : [0x60, 0x00, 0x03, 0x5E], value: 50),
    EffectParameter(id: '${prefix}_tw_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x01, 0x51] : [0x60, 0x00, 0x03, 0x5D], unit: '%', value: 50),
  ];

  static List<EffectParameter> _buildSubWah(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_sw_pos', name: 'Position', address: isFx1 ? [0x60, 0x00, 0x01, 0x5D] : [0x60, 0x00, 0x03, 0x69], value: 50),
    EffectParameter(id: '${prefix}_sw_min', name: 'Pedal Min', address: isFx1 ? [0x60, 0x00, 0x01, 0x5E] : [0x60, 0x00, 0x03, 0x6A], value: 0),
    EffectParameter(id: '${prefix}_sw_max', name: 'Pedal Max', address: isFx1 ? [0x60, 0x00, 0x01, 0x5F] : [0x60, 0x00, 0x03, 0x6B], value: 100),
    EffectParameter(id: '${prefix}_sw_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x60] : [0x60, 0x00, 0x03, 0x6C], value: 100),
    EffectParameter(id: '${prefix}_sw_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x01, 0x61] : [0x60, 0x00, 0x03, 0x6D], unit: '%', value: 0),
  ];

  static List<EffectParameter> _buildBassSynth(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_bs_wave', name: 'Wave', address: isFx1 ? [0x60, 0x00, 0x02, 0x20] : [0x60, 0x00, 0x04, 0x2C], options: waveTypes, value: 0),
    EffectParameter(id: '${prefix}_bs_cutoff', name: 'Cutoff', address: isFx1 ? [0x60, 0x00, 0x02, 0x21] : [0x60, 0x00, 0x04, 0x2D], value: 50),
    EffectParameter(id: '${prefix}_bs_reso', name: 'Reso', address: isFx1 ? [0x60, 0x00, 0x02, 0x22] : [0x60, 0x00, 0x04, 0x2E], value: 50),
    EffectParameter(id: '${prefix}_bs_sens', name: 'Sens', address: isFx1 ? [0x60, 0x00, 0x02, 0x23] : [0x60, 0x00, 0x04, 0x2F], value: 45),
    EffectParameter(id: '${prefix}_bs_decay', name: 'Decay', address: isFx1 ? [0x60, 0x00, 0x02, 0x24] : [0x60, 0x00, 0x04, 0x30], value: 50),
    EffectParameter(id: '${prefix}_bs_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x02, 0x25] : [0x60, 0x00, 0x04, 0x31], value: 60),
    EffectParameter(id: '${prefix}_bs_level', name: 'Synth Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x26] : [0x60, 0x00, 0x04, 0x32], value: 60),
    EffectParameter(id: '${prefix}_bs_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x02, 0x27] : [0x60, 0x00, 0x04, 0x33], unit: '%', value: 40),
  ];

  static List<EffectParameter> _buildCompressor(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_cmp_sustain', name: 'Sustain', address: isFx1 ? [0x60, 0x00, 0x01, 0x64] : [0x60, 0x00, 0x03, 0x70], value: 50),
    EffectParameter(id: '${prefix}_cmp_attack', name: 'Attack', address: isFx1 ? [0x60, 0x00, 0x01, 0x65] : [0x60, 0x00, 0x03, 0x71], value: 50),
    EffectParameter(id: '${prefix}_cmp_tone', name: 'Tone', address: isFx1 ? [0x60, 0x00, 0x01, 0x66] : [0x60, 0x00, 0x03, 0x72], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_cmp_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x67] : [0x60, 0x00, 0x03, 0x73], value: 60),
  ];

  static List<EffectParameter> _buildLimiter(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_lim_attack', name: 'Attack', address: isFx1 ? [0x60, 0x00, 0x01, 0x6A] : [0x60, 0x00, 0x03, 0x76], value: 30),
    EffectParameter(id: '${prefix}_lim_thresh', name: 'Thresh', address: isFx1 ? [0x60, 0x00, 0x01, 0x6B] : [0x60, 0x00, 0x03, 0x77], value: 40),
    EffectParameter(id: '${prefix}_lim_ratio', name: 'Ratio', address: isFx1 ? [0x60, 0x00, 0x01, 0x6C] : [0x60, 0x00, 0x03, 0x78], value: 50),
    EffectParameter(id: '${prefix}_lim_release', name: 'Release', address: isFx1 ? [0x60, 0x00, 0x01, 0x6D] : [0x60, 0x00, 0x03, 0x79], value: 40),
    EffectParameter(id: '${prefix}_lim_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x6E] : [0x60, 0x00, 0x03, 0x7A], value: 60),
  ];

  static List<EffectParameter> _buildToneModify(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_tm_reso', name: 'Reso', address: isFx1 ? [0x60, 0x00, 0x02, 0x09] : [0x60, 0x00, 0x04, 0x15], value: 50),
    EffectParameter(id: '${prefix}_tm_low', name: 'Low', address: isFx1 ? [0x60, 0x00, 0x02, 0x0A] : [0x60, 0x00, 0x04, 0x16], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_tm_high', name: 'High', address: isFx1 ? [0x60, 0x00, 0x02, 0x0B] : [0x60, 0x00, 0x04, 0x17], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_tm_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x0C] : [0x60, 0x00, 0x04, 0x18], value: 60),
  ];

  static List<EffectParameter> _buildBassSim(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_sim_low', name: 'Low', address: isFx1 ? [0x60, 0x00, 0x02, 0x0F] : [0x60, 0x00, 0x04, 0x1B], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_sim_high', name: 'High', address: isFx1 ? [0x60, 0x00, 0x02, 0x10] : [0x60, 0x00, 0x04, 0x1C], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_sim_body', name: 'Body', address: isFx1 ? [0x60, 0x00, 0x02, 0x12] : [0x60, 0x00, 0x04, 0x1E], value: 50),
    EffectParameter(id: '${prefix}_sim_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x11] : [0x60, 0x00, 0x04, 0x1D], value: 60),
  ];

  static List<EffectParameter> _buildSlowGear(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_sg_sens', name: 'Sens', address: isFx1 ? [0x60, 0x00, 0x02, 0x14] : [0x60, 0x00, 0x04, 0x20], value: 60),
    EffectParameter(id: '${prefix}_sg_rise', name: 'Rise Time', address: isFx1 ? [0x60, 0x00, 0x02, 0x15] : [0x60, 0x00, 0x04, 0x21], value: 50),
    EffectParameter(id: '${prefix}_sg_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x16] : [0x60, 0x00, 0x04, 0x22], value: 60),
  ];

  static List<EffectParameter> _buildPitchShifter(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_ps_pitch', name: 'Pitch', address: isFx1 ? [0x60, 0x00, 0x02, 0x37] : [0x60, 0x00, 0x04, 0x43], displayOffset: -24, value: 24),
    EffectParameter(id: '${prefix}_ps_fine', name: 'Fine', address: isFx1 ? [0x60, 0x00, 0x02, 0x38] : [0x60, 0x00, 0x04, 0x44], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_ps_level', name: 'PS Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x3B] : [0x60, 0x00, 0x04, 0x47], value: 60),
    EffectParameter(id: '${prefix}_ps_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x02, 0x43] : [0x60, 0x00, 0x04, 0x4F], unit: '%', value: 80),
  ];

  static List<EffectParameter> _buildHarmonist(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_hr_harm', name: 'Harmony', address: isFx1 ? [0x60, 0x00, 0x02, 0x46] : [0x60, 0x00, 0x04, 0x52], displayOffset: -12, value: 12),
    EffectParameter(id: '${prefix}_hr_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x49] : [0x60, 0x00, 0x04, 0x55], value: 60),
    EffectParameter(id: '${prefix}_hr_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x02, 0x4F] : [0x60, 0x00, 0x04, 0x5B], unit: '%', value: 80),
  ];

  static List<EffectParameter> _buildPhaser(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_ph_rate', name: 'Rate', address: isFx1 ? [0x60, 0x00, 0x02, 0x76] : [0x60, 0x00, 0x05, 0x02], value: 45),
    EffectParameter(id: '${prefix}_ph_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x02, 0x77] : [0x60, 0x00, 0x05, 0x03], value: 60),
    EffectParameter(id: '${prefix}_ph_reso', name: 'Reso', address: isFx1 ? [0x60, 0x00, 0x02, 0x79] : [0x60, 0x00, 0x05, 0x05], value: 40),
    EffectParameter(id: '${prefix}_ph_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x02, 0x7B] : [0x60, 0x00, 0x05, 0x07], value: 60),
    EffectParameter(id: '${prefix}_ph_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x02, 0x7C] : [0x60, 0x00, 0x05, 0x08], unit: '%', value: 60),
  ];

  static List<EffectParameter> _buildFlanger(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_fl_rate', name: 'Rate', address: isFx1 ? [0x60, 0x00, 0x02, 0x7E] : [0x60, 0x00, 0x05, 0x0A], value: 40),
    EffectParameter(id: '${prefix}_fl_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x02, 0x7F] : [0x60, 0x00, 0x05, 0x0B], value: 60),
    EffectParameter(id: '${prefix}_fl_reso', name: 'Reso', address: isFx1 ? [0x60, 0x00, 0x03, 0x01] : [0x60, 0x00, 0x05, 0x0D], value: 40),
    EffectParameter(id: '${prefix}_fl_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x03, 0x04] : [0x60, 0x00, 0x05, 0x10], value: 60),
    EffectParameter(id: '${prefix}_fl_direct', name: 'Direct Level', address: isFx1 ? [0x60, 0x00, 0x03, 0x05] : [0x60, 0x00, 0x05, 0x11], value: 80),
  ];

  static List<EffectParameter> _buildTremolo(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_tr_rate', name: 'Rate', address: isFx1 ? [0x60, 0x00, 0x03, 0x08] : [0x60, 0x00, 0x05, 0x14], value: 50),
    EffectParameter(id: '${prefix}_tr_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x03, 0x09] : [0x60, 0x00, 0x05, 0x15], value: 60),
    EffectParameter(id: '${prefix}_tr_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x03, 0x0A] : [0x60, 0x00, 0x05, 0x16], value: 60),
  ];

  static List<EffectParameter> _buildRotary(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_ro_rate_s', name: 'Rate Slow', address: isFx1 ? [0x60, 0x00, 0x03, 0x0D] : [0x60, 0x00, 0x05, 0x19], value: 30),
    EffectParameter(id: '${prefix}_ro_rate_f', name: 'Rate Fast', address: isFx1 ? [0x60, 0x00, 0x03, 0x0E] : [0x60, 0x00, 0x05, 0x1A], value: 70),
    EffectParameter(id: '${prefix}_ro_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x03, 0x11] : [0x60, 0x00, 0x05, 0x1D], value: 60),
    EffectParameter(id: '${prefix}_ro_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x03, 0x12] : [0x60, 0x00, 0x05, 0x1E], value: 60),
  ];

  static List<EffectParameter> _buildChorus(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_ch_rate', name: 'Rate', address: isFx1 ? [0x60, 0x00, 0x10, 0x4F] : [0x60, 0x00, 0x10, 0x61], value: 40),
    EffectParameter(id: '${prefix}_ch_depth', name: 'Depth', address: isFx1 ? [0x60, 0x00, 0x10, 0x50] : [0x60, 0x00, 0x10, 0x62], value: 50),
    EffectParameter(id: '${prefix}_ch_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x10, 0x54] : [0x60, 0x00, 0x10, 0x66], value: 60),
  ];

  static List<EffectParameter> _buildSubOdDs(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_od_drive', name: 'Drive', address: isFx1 ? [0x60, 0x00, 0x01, 0x43] : [0x60, 0x00, 0x03, 0x4F], value: 50),
    EffectParameter(id: '${prefix}_od_bottom', name: 'Bottom', address: isFx1 ? [0x60, 0x00, 0x01, 0x44] : [0x60, 0x00, 0x03, 0x50], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_od_tone', name: 'Tone', address: isFx1 ? [0x60, 0x00, 0x01, 0x45] : [0x60, 0x00, 0x03, 0x51], displayOffset: -50, value: 50),
    EffectParameter(id: '${prefix}_od_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x48] : [0x60, 0x00, 0x03, 0x54], value: 50),
    EffectParameter(id: '${prefix}_od_direct', name: 'Direct Mix', address: isFx1 ? [0x60, 0x00, 0x01, 0x49] : [0x60, 0x00, 0x03, 0x55], unit: '%', value: 0),
  ];

  static List<EffectParameter> _buildGeneric(bool isFx1, String prefix) => [
    EffectParameter(id: '${prefix}_gen_sens', name: 'Sens', address: isFx1 ? [0x60, 0x00, 0x01, 0x4E] : [0x60, 0x00, 0x03, 0x5A], value: 50),
    EffectParameter(id: '${prefix}_gen_level', name: 'Level', address: isFx1 ? [0x60, 0x00, 0x01, 0x52] : [0x60, 0x00, 0x03, 0x5E], value: 50),
  ];
}
