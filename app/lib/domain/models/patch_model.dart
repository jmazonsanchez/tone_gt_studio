import 'package:flutter/foundation.dart';
import '../../models/effect_block.dart';

/// Banco al que pertenece el preset en la Boss GT-1B.
enum PatchBank {
  /// Presets de usuario editables y guardables (U01 a U99, índices 0 a 98).
  user,

  /// Presets de fábrica de solo lectura (P01 a P99, índices 99 a 197).
  preset,
}

/// Referencia identificadora de un preset en la Boss GT-1B.
@immutable
class PatchRef {
  final PatchBank bank;
  final int number; // 1 a 99

  const PatchRef({
    required this.bank,
    required this.number,
  }) : assert(number >= 1 && number <= 99, 'El número de preset debe estar entre 1 y 99');

  /// Índice numérico crudo del protocolo GT-1B (0 a 197).
  int get rawIndex => bank == PatchBank.user ? (number - 1) : (98 + number);

  /// Si este preset es de fábrica y no puede sobrescribirse directamente en EEPROM.
  bool get isReadOnly => bank == PatchBank.preset;

  /// Etiqueta visual de escenario (ej. 'U01' o 'P45').
  String get displayNumber {
    final prefix = bank == PatchBank.user ? 'U' : 'P';
    return '$prefix${number.toString().padLeft(2, '0')}';
  }

  /// Construye un PatchRef a partir del índice crudo de 0 a 197.
  factory PatchRef.fromRawIndex(int rawIndex) {
    if (rawIndex < 99) {
      return PatchRef(bank: PatchBank.user, number: rawIndex + 1);
    } else {
      final pNum = (rawIndex - 99) + 1;
      return PatchRef(bank: PatchBank.preset, number: pNum.clamp(1, 99));
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchRef && runtimeType == other.runtimeType && bank == other.bank && number == other.number;

  @override
  int get hashCode => bank.hashCode ^ number.hashCode;

  @override
  String toString() => displayNumber;
}

/// Estado inmutable de un patch activo.
@immutable
class PatchState {
  final PatchRef ref;
  final String name;
  final List<EffectBlock> effects;
  final bool isModified;

  const PatchState({
    required this.ref,
    required this.name,
    required this.effects,
    this.isModified = false,
  });

  PatchState copyWith({
    PatchRef? ref,
    String? name,
    List<EffectBlock>? effects,
    bool? isModified,
  }) {
    return PatchState(
      ref: ref ?? this.ref,
      name: name ?? this.name,
      effects: effects ?? this.effects,
      isModified: isModified ?? this.isModified,
    );
  }
}
