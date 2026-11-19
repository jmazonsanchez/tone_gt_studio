/// Model representing a quick-access preset shortcut for live performance.
class QuickPreset {
  final String id;
  final int patchIndex;
  final String customLabel;
  final int colorValue; // ARGB color integer for visual tagging on stage

  const QuickPreset({
    required this.id,
    required this.patchIndex,
    this.customLabel = '',
    this.colorValue = 0xFF00ADB5, // Default GT-1B Cyan
  });

  QuickPreset copyWith({
    String? id,
    int? patchIndex,
    String? customLabel,
    int? colorValue,
  }) {
    return QuickPreset(
      id: id ?? this.id,
      patchIndex: patchIndex ?? this.patchIndex,
      customLabel: customLabel ?? this.customLabel,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patchIndex': patchIndex,
        'customLabel': customLabel,
        'colorValue': colorValue,
      };

  factory QuickPreset.fromJson(Map<String, dynamic> json) => QuickPreset(
        id: json['id'] as String,
        patchIndex: json['patchIndex'] as int,
        customLabel: json['customLabel'] as String? ?? '',
        colorValue: json['colorValue'] as int? ?? 0xFF00ADB5,
      );
}
