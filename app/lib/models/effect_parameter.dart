/// Model representing an individual controllable parameter of an effect block.
class EffectParameter {
  final String id;
  final String name;
  final List<int> address; // 4-byte SysEx address (e.g. [0x60, 0x00, 0x00, 0x32])
  final int min;
  final int max;
  final String unit;
  int value;

  EffectParameter({
    required this.id,
    required this.name,
    required this.address,
    this.min = 0,
    this.max = 100,
    this.unit = '',
    required this.value,
  });

  EffectParameter copyWith({int? value}) {
    return EffectParameter(
      id: id,
      name: name,
      address: address,
      min: min,
      max: max,
      unit: unit,
      value: value ?? this.value,
    );
  }
}
