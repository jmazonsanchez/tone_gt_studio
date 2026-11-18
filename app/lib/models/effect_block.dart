import 'package:flutter/material.dart';

enum EffectCategory {
  comp,
  odDs,
  preamp,
  fx1,
  fx2,
  delay,
  chorus,
  reverb,
}

class EffectBlock {
  final String id;
  final String name;
  final String subtitle;
  final EffectCategory category;
  final Color accentColor;
  bool isEnabled;

  EffectBlock({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.accentColor,
    this.isEnabled = false,
  });

  EffectBlock copyWith({bool? isEnabled}) {
    return EffectBlock(
      id: id,
      name: name,
      subtitle: subtitle,
      category: category,
      accentColor: accentColor,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
