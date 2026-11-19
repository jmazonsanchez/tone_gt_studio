/// Data models for Boss GT-1B Control (CTL1, CTL2, CTL3), Expression (EXP1, EXP2, EXP1 SW),
/// Footswitches (Down, Up), Levels (In/Out), and Assign Matrices A1–A6.
class AssignSetting {
  final int index; // 1..6 (A1 to A6)
  final bool isEnabled;
  final int target;
  final int targetMin;
  final int targetMax;
  final int source;
  final int sourceMode; // 0 = MOMENT, 1 = TOGGLE
  final int actRangeLo;
  final int actRangeHi;

  const AssignSetting({
    required this.index,
    this.isEnabled = false,
    this.target = 0,
    this.targetMin = 0,
    this.targetMax = 100,
    this.source = 0,
    this.sourceMode = 0,
    this.actRangeLo = 0,
    this.actRangeHi = 127,
  });

  AssignSetting copyWith({
    bool? isEnabled,
    int? target,
    int? targetMin,
    int? targetMax,
    int? source,
    int? sourceMode,
    int? actRangeLo,
    int? actRangeHi,
  }) {
    return AssignSetting(
      index: index,
      isEnabled: isEnabled ?? this.isEnabled,
      target: target ?? this.target,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      source: source ?? this.source,
      sourceMode: sourceMode ?? this.sourceMode,
      actRangeLo: actRangeLo ?? this.actRangeLo,
      actRangeHi: actRangeHi ?? this.actRangeHi,
    );
  }
}

class CtlExpSetting {
  // CTL 1 & EXP 1
  final int expFunc;
  final int expMin;
  final int expMax;
  final int expSwFunc;
  final int expSwMin;
  final int expSwMax;
  final int expSwMode;
  final int ctl1Func;
  final int ctl1Min;
  final int ctl1Max;
  final int ctl1Mode; // 0 = MOMENT, 1 = TOGGLE

  // CTL 2, CTL 3 & EXP 2 (External / Sub Controls)
  final int ctl2Func;
  final int ctl2Mode;
  final int ctl3Func;
  final int ctl3Mode;
  final int exp2Func;
  final int exp2Min;
  final int exp2Max;

  // Footswitches Down & Up
  final int downFunc;
  final int downMode;
  final int upFunc;
  final int upMode;

  // Levels: In Level & Out Level
  final int inLevel;
  final int outLevel;

  const CtlExpSetting({
    this.expFunc = 1,
    this.expMin = 0,
    this.expMax = 100,
    this.expSwFunc = 1,
    this.expSwMin = 0,
    this.expSwMax = 1,
    this.expSwMode = 1,
    this.ctl1Func = 14,
    this.ctl1Min = 0,
    this.ctl1Max = 1,
    this.ctl1Mode = 1,
    this.ctl2Func = 0,
    this.ctl2Mode = 1,
    this.ctl3Func = 0,
    this.ctl3Mode = 1,
    this.exp2Func = 0,
    this.exp2Min = 0,
    this.exp2Max = 100,
    this.downFunc = 0,
    this.downMode = 0,
    this.upFunc = 0,
    this.upMode = 0,
    this.inLevel = 50,
    this.outLevel = 50,
  });

  CtlExpSetting copyWith({
    int? expFunc,
    int? expMin,
    int? expMax,
    int? expSwFunc,
    int? expSwMin,
    int? expSwMax,
    int? expSwMode,
    int? ctl1Func,
    int? ctl1Min,
    int? ctl1Max,
    int? ctl1Mode,
    int? ctl2Func,
    int? ctl2Mode,
    int? ctl3Func,
    int? ctl3Mode,
    int? exp2Func,
    int? exp2Min,
    int? exp2Max,
    int? downFunc,
    int? downMode,
    int? upFunc,
    int? upMode,
    int? inLevel,
    int? outLevel,
  }) {
    return CtlExpSetting(
      expFunc: expFunc ?? this.expFunc,
      expMin: expMin ?? this.expMin,
      expMax: expMax ?? this.expMax,
      expSwFunc: expSwFunc ?? this.expSwFunc,
      expSwMin: expSwMin ?? this.expSwMin,
      expSwMax: expSwMax ?? this.expSwMax,
      expSwMode: expSwMode ?? this.expSwMode,
      ctl1Func: ctl1Func ?? this.ctl1Func,
      ctl1Min: ctl1Min ?? this.ctl1Min,
      ctl1Max: ctl1Max ?? this.ctl1Max,
      ctl1Mode: ctl1Mode ?? this.ctl1Mode,
      ctl2Func: ctl2Func ?? this.ctl2Func,
      ctl2Mode: ctl2Mode ?? this.ctl2Mode,
      ctl3Func: ctl3Func ?? this.ctl3Func,
      ctl3Mode: ctl3Mode ?? this.ctl3Mode,
      exp2Func: exp2Func ?? this.exp2Func,
      exp2Min: exp2Min ?? this.exp2Min,
      exp2Max: exp2Max ?? this.exp2Max,
      downFunc: downFunc ?? this.downFunc,
      downMode: downMode ?? this.downMode,
      upFunc: upFunc ?? this.upFunc,
      upMode: upMode ?? this.upMode,
      inLevel: inLevel ?? this.inLevel,
      outLevel: outLevel ?? this.outLevel,
    );
  }
}
