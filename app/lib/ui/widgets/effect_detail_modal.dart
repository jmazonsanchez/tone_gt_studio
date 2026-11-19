import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/effect_block.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';
import 'parameter_knob.dart';

class EffectDetailModal extends StatelessWidget {
  final EffectBlock effect;

  const EffectDetailModal({super.key, required this.effect});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = colors.isDark;
    final patchService = context.watch<PatchService>();
    final active = effect.isEnabled;
    final color = effect.accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ON/OFF switch
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effect.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      effect.subtitle,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                activeColor: color,
                onChanged: (val) => patchService.toggleEffect(effect),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),

          // Parameter Knobs Section
          Text(
            'PARÁMETROS EN VIVO (DT1 SYSEX)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          if (effect.parameters.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No hay parámetros adicionales para este bloque', style: TextStyle(color: colors.textMuted)),
              ),
            )
          else
            Center(
              child: Wrap(
                spacing: 28,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: effect.parameters.map((param) {
                  return ParameterKnob(
                    parameter: param,
                    accentColor: color,
                    onChanged: (newVal) {
                      patchService.updateParameter(param, newVal);
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 28),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('LISTO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
