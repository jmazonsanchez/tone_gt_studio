import 'package:flutter/material.dart';
import 'effect_parameter.dart';

enum EffectCategory {
  comp,
  odDs,
  preamp,
  fx1,
  fx2,
  delay,
  chorus,
  reverb,
  pedalFx, // WAH / Pedal Bend / Expression Footswitch
}

class EffectBlock {
  final String id;
  final String name;
  final String subtitle;
  final EffectCategory category;
  final Color accentColor;
  bool isEnabled;
  final List<EffectParameter> parameters;

  EffectBlock({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.accentColor,
    this.isEnabled = false,
    List<EffectParameter>? parameters,
  }) : parameters = parameters ?? [];

  EffectBlock copyWith({bool? isEnabled, List<EffectParameter>? parameters}) {
    return EffectBlock(
      id: id,
      name: name,
      subtitle: subtitle,
      category: category,
      accentColor: accentColor,
      isEnabled: isEnabled ?? this.isEnabled,
      parameters: parameters ?? this.parameters,
    );
  }
}
