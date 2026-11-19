/// Status states for Boss GT-1B Phrase Loop engine.
enum LooperStatus {
  stopped,
  countdown,
  recording,
  playing,
  overdubbing,
}

/// Recording mode order for Phrase Loop:
/// recPlay: Record -> Play -> Overdub (Default)
/// recDub: Record -> Overdub -> Play
enum LooperRecMode {
  recPlay,
  recDub,
}

/// Settings model for Boss GT-1B Phrase Loop (Looper 32s).
class PhraseLoopSettings {
  bool isEnabled;
  int playLevel; // 1..120 % (default 100)
  LooperRecMode recMode;
  int startTimerSeconds; // Pre-roll countdown timer: 0 (immediate), 2, 3, 5, 10 seconds
  int maxDurationSeconds; // Auto-stop duration: 0 (manual/up to 32s), 4, 8, 16, 32 seconds

  PhraseLoopSettings({
    this.isEnabled = false,
    this.playLevel = 100,
    this.recMode = LooperRecMode.recPlay,
    this.startTimerSeconds = 3,
    this.maxDurationSeconds = 0,
  });

  String get recModeLabel => recMode == LooperRecMode.recPlay ? 'REC → PLAY' : 'REC → DUB';
}
