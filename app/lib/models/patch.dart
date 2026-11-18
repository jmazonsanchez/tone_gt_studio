import 'effect_block.dart';

class Patch {
  final int index; // 0 to 98 (User Patches U01 - U99) o 99 to 197 (Preset Patches P01 - P99)
  final String name;
  final List<EffectBlock> effects;

  Patch({
    required this.index,
    required this.name,
    required this.effects,
  });

  bool get isReadOnly => index >= 99;

  String get displayNumber {
    if (index < 99) {
      return 'U${(index + 1).toString().padLeft(2, '0')}';
    } else {
      final pNum = (index - 99) + 1;
      return 'P${pNum.toString().padLeft(2, '0')}';
    }
  }

  Patch copyWith({
    int? index,
    String? name,
    List<EffectBlock>? effects,
  }) {
    return Patch(
      index: index ?? this.index,
      name: name ?? this.name,
      effects: effects ?? this.effects,
    );
  }
}
