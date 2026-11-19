/// Data models for Boss GT-1B Control (CTL1), Expression (EXP/EXP SW), and Assign Matrices 1-8.
class AssignSetting {
  final int index; // 1..8
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
  final int expFunc;
  final int expMin;
  final int expMax;
  final int expSwFunc;
  final int expSwMin;
  final int expSwMax;
  final int ctl1Func;
  final int ctl1Min;
  final int ctl1Max;
  final int ctl1Mode; // 0 = MOMENT, 1 = TOGGLE

  const CtlExpSetting({
    this.expFunc = 1,
    this.expMin = 0,
    this.expMax = 100,
    this.expSwFunc = 1,
    this.expSwMin = 0,
    this.expSwMax = 1,
    this.ctl1Func = 14,
    this.ctl1Min = 0,
    this.ctl1Max = 1,
    this.ctl1Mode = 1,
  });

  CtlExpSetting copyWith({
    int? expFunc,
    int? expMin,
    int? expMax,
    int? expSwFunc,
    int? expSwMin,
    int? expSwMax,
    int? ctl1Func,
    int? ctl1Min,
    int? ctl1Max,
    int? ctl1Mode,
  }) {
    return CtlExpSetting(
      expFunc: expFunc ?? this.expFunc,
      expMin: expMin ?? this.expMin,
      expMax: expMax ?? this.expMax,
      expSwFunc: expSwFunc ?? this.expSwFunc,
      expSwMin: expSwMin ?? this.expSwMin,
      expSwMax: expSwMax ?? this.expSwMax,
      ctl1Func: ctl1Func ?? this.ctl1Func,
      ctl1Min: ctl1Min ?? this.ctl1Min,
      ctl1Max: ctl1Max ?? this.ctl1Max,
      ctl1Mode: ctl1Mode ?? this.ctl1Mode,
    );
  }
}
