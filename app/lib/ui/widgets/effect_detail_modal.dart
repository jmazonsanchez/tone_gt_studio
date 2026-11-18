import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/effect_block.dart';
import '../../services/patch_service.dart';
import 'parameter_knob.dart';

class EffectDetailModal extends StatelessWidget {
  final EffectBlock effect;

  const EffectDetailModal({super.key, required this.effect});

  @override
  Widget build(BuildContext context) {
    final patchService = context.watch<PatchService>();
    final active = effect.isEnabled;
    final color = effect.accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: color.withOpacity(0.2),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      effect.subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.white54),
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
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Parameter Knobs Section
          const Text(
            'PARÁMETROS EN VIVO (DT1 SYSEX)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          if (effect.parameters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay parámetros adicionales para este bloque', style: TextStyle(color: Colors.white30)),
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
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
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
