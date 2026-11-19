import '../domain/gt1b_catalog.dart';

/// Model representing an individual controllable parameter of an effect block.
class EffectParameter {
  final String id;
  final String name;
  final List<int> address; // 4-byte SysEx address (e.g. [0x60, 0x00, 0x00, 0x32])
  final int min;
  final int max;
  final String unit;
  final List<String>? options;
  final bool isToggle;
  final int displayOffset;
  int value;

  EffectParameter({
    required this.id,
    required this.name,
    required this.address,
    this.min = 0,
    this.max = 100,
    this.unit = '',
    this.options,
    this.isToggle = false,
    this.displayOffset = 0,
    required this.value,
  });

  factory EffectParameter.fromDef(ParamDef def, {int? initialValue}) {
    return EffectParameter(
      id: def.id,
      name: def.name,
      address: def.address,
      min: def.min,
      max: def.max,
      unit: def.unit ?? '',
      options: def.options,
      isToggle: def.isToggle,
      displayOffset: def.displayOffset,
      value: initialValue ?? def.defaultValue,
    );
  }

  bool get isEnum => options != null && options!.isNotEmpty;

  String get formattedValue {
    if (isToggle) {
      return value > 0 ? 'ON' : 'OFF';
    }
    if (isEnum && options != null) {
      final idx = value.clamp(0, options!.length - 1);
      return options![idx];
    }
    final adjusted = value + displayOffset;
    if (unit.isNotEmpty) {
      return '$adjusted $unit';
    }
    return '$adjusted';
  }

  EffectParameter copyWith({int? value}) {
    return EffectParameter(
      id: id,
      name: name,
      address: address,
      min: min,
      max: max,
      unit: unit,
      options: options,
      isToggle: isToggle,
      displayOffset: displayOffset,
      value: value ?? this.value,
    );
  }
}
