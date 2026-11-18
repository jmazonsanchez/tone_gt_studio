import 'effect_block.dart';

class Patch {
  final int index; // 0 to 98 (User Patches U01 - U99)
  final String name;
  final List<EffectBlock> effects;

  Patch({
    required this.index,
    required this.name,
    required this.effects,
  });

  String get displayNumber => 'U${(index + 1).toString().padLeft(2, '0')}';

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
