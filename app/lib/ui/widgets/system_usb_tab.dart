import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../services/patch_service.dart';
import '../theme/app_theme.dart';

/// USB Audio & Hardware Utilities Tab for Boss GT-1B
class SystemUsbTab extends StatelessWidget {
  final PatchService patchService;

  const SystemUsbTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sys = patchService.systemSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUsbPrimarySection(sys, colors),
          const SizedBox(height: 14),
          _buildUsbSecondarySection(sys, colors),
          const SizedBox(height: 14),
          _buildAutoOffCard(sys, colors),
        ],
      ),
    );
  }

  Widget _buildUsbPrimarySection(SystemSettings sys, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('USB AUDIO PRINCIPAL (DAW / GRABACIÓN)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSlider(
                  colors: colors,
                  label: 'PRIMARY OUTPUT',
                  value: sys.usbPrimaryOut,
                  displayValue: '${sys.usbPrimaryOut} %',
                  onChanged: (v) => patchService.updateSystemParameter('usb_primary_out', v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSlider(
                  colors: colors,
                  label: 'PRIMARY MIX',
                  value: sys.usbPrimaryMix,
                  displayValue: '${sys.usbPrimaryMix} %',
                  onChanged: (v) => patchService.updateSystemParameter('usb_primary_mix', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsbSecondarySection(SystemSettings sys, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DIRECT MONITOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              Text('Escucha directa sin latencia de la señal del bajo', style: TextStyle(fontSize: 9, color: colors.textMuted)),
            ],
          ),
          Switch(
            value: sys.usbDirectMonitor,
            activeColor: colors.primary,
            onChanged: (val) => patchService.updateSystemParameter('usb_direct_monitor', val ? 1 : 0),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoOffCard(SystemSettings sys, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AUTO OFF (APAGADO AUTOMÁTICO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              Text('Apaga la pedalera tras 10 horas de inactividad', style: TextStyle(fontSize: 9, color: colors.textMuted)),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: sys.autoOff.clamp(0, 1),
              isDense: true,
              dropdownColor: colors.surfaceElevated,
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              items: const [
                DropdownMenuItem(value: 0, child: Text('DESACTIVADO')),
                DropdownMenuItem(value: 1, child: Text('10 HORAS')),
              ],
              onChanged: (val) {
                if (val != null) patchService.updateSystemParameter('auto_off', val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required AppColorScheme colors,
    required String label,
    required int value,
    required String displayValue,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8, color: colors.textMuted))),
              Text(displayValue, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.primary)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.sliderInactiveTrack,
              thumbColor: colors.primary,
            ),
            child: Slider(
              value: value.clamp(0, 100).toDouble(),
              min: 0,
              max: 100,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
