// Boss GT-1B System & Global Settings Model (Phase 6)

class SystemSettings {
  // Global Output & Input
  int outputSelect; // 0: Line/Phones, 1: Bass Amp Clean, 2: Bass Amp Drive
  int inputLevel; // -10 dB .. +10 dB (raw: 0..20, display: val - 10)
  int totalReverb; // 0..100 %

  // Global 4-Band Parametric EQ (00 00 00 72..76)
  int eqLowGain; // -20..+20 dB (raw: 0..40, display: val - 20)
  int eqMidGain; // -20..+20 dB (raw: 0..40, display: val - 20)
  int eqMidFreq; // 0..20 (100 Hz .. 10.0 kHz)
  int eqMidQ; // 0..5 (0.5 .. 16)
  int eqHighGain; // -20..+20 dB (raw: 0..40, display: val - 20)

  // Metronome (00 00 00 30..34)
  bool metronomeOn;
  int metronomeTempo; // 20..250 BPM
  int metronomeBeat; // 0..9 (1/4 .. 7/8)
  int metronomeLevel; // 0..100

  // Tuner Settings (00 00 00 20..21)
  int tunerPitch; // 0..10 (435 Hz .. 445 Hz, default 5 = 440 Hz)
  int tunerOutput; // 0: Mute, 1: Bypass, 2: Thru

  // Live Chromatic Tuner Pitch Stream (7F 00 05 00)
  String liveNote;
  int liveCents; // -50 .. +50 cents (raw 0..100)
  bool inTune;

  // USB Audio (00 00 00 51..57)
  int usbPrimaryOut; // 0..100 %
  int usbPrimaryMix; // 0..100 %
  bool usbDirectMonitor; // false: Off, true: On
  int usbSecondaryIn; // 0..100 %
  int usbSecondaryOut; // 0..100 %

  // Hardware Preferences (00 00 00 60)
  int autoOff; // 0: Off, 1: 10 Hours

  SystemSettings({
    this.outputSelect = 0,
    this.inputLevel = 10,
    this.totalReverb = 100,
    this.eqLowGain = 20,
    this.eqMidGain = 20,
    this.eqMidFreq = 10,
    this.eqMidQ = 1,
    this.eqHighGain = 20,
    this.metronomeOn = false,
    this.metronomeTempo = 120,
    this.metronomeBeat = 3, // 4/4
    this.metronomeLevel = 80,
    this.tunerPitch = 5, // 440 Hz
    this.tunerOutput = 0, // Mute
    this.liveNote = '---',
    this.liveCents = 0,
    this.inTune = false,
    this.usbPrimaryOut = 100,
    this.usbPrimaryMix = 100,
    this.usbDirectMonitor = true,
    this.usbSecondaryIn = 100,
    this.usbSecondaryOut = 100,
    this.autoOff = 1, // 10 Hours
  });

  static const List<String> chromaticNotes = [
    'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'
  ];

  static const List<String> outputSelectOptions = [
    'LINE / PHONES',
    'BASS AMP (CLEAN)',
    'BASS AMP (DRIVE)',
  ];

  static const List<String> beatLabels = [
    '1/4', '2/4', '3/4', '4/4', '5/4', '6/4', '7/4', '5/8', '6/8', '7/8'
  ];

  static const List<String> tunerOutputOptions = [
    'MUTE (SILENCIO)',
    'BYPASS (DIRECTO)',
    'THRU (PASO)',
  ];

  /// Update live pitch reading received from GT-1B stream (7F 00 05 00)
  void updateLivePitch(int noteIndex, int rawCentValue) {
    if (noteIndex >= 0 && noteIndex < chromaticNotes.length) {
      liveNote = chromaticNotes[noteIndex];
    } else {
      liveNote = '---';
    }
    // rawCentValue: 0..100, where 50 is exact pitch center (0 cents)
    liveCents = (rawCentValue - 50).clamp(-50, 50);
    inTune = liveCents.abs() <= 3;
  }
}
