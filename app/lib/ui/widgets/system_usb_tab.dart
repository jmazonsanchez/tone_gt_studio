import 'package:flutter/material.dart';
import '../../models/system_settings.dart';
import '../../services/patch_service.dart';

/// USB Audio & Hardware Utilities Tab for Boss GT-1B
class SystemUsbTab extends StatelessWidget {
  final PatchService patchService;

  const SystemUsbTab({super.key, required this.patchService});

  @override
  Widget build(BuildContext context) {
    final sys = patchService.systemSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. USB Primary Audio (DAW Output & Mix)
          _buildUsbPrimarySection(sys),
          const SizedBox(height: 14),

          // 2. Direct Monitor & Secondary Audio
          _buildUsbSecondarySection(sys),
          const SizedBox(height: 14),

          // 3. Hardware Auto-Off
          _buildAutoOffCard(sys),
        ],
      ),
    );
  }

  Widget _buildUsbPrimarySection(SystemSettings sys) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('USB AUDIO PRINCIPAL (DAW / GRABACIÓN)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSlider(
                  label: 'PRIMARY OUTPUT',
                  value: sys.usbPrimaryOut,
                  displayValue: '${sys.usbPrimaryOut} %',
                  onChanged: (v) => patchService.updateSystemParameter('usb_primary_out', v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSlider(
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

  Widget _buildUsbSecondarySection(SystemSettings sys) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIRECT MONITOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Escucha directa sin latencia de la señal del bajo', style: TextStyle(fontSize: 9, color: Colors.white38)),
                ],
              ),
              Switch(
                value: sys.usbDirectMonitor,
                activeColor: const Color(0xFF00ADB5),
                onChanged: (val) => patchService.updateSystemParameter('usb_direct_monitor', val ? 1 : 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoOffCard(SystemSettings sys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AUTO OFF (APAGADO AUTOMÁTICO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Apaga la pedalera tras 10 horas de inactividad', style: TextStyle(fontSize: 9, color: Colors.white38)),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: sys.autoOff.clamp(0, 1),
              isDense: true,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 11),
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
    required String label,
    required int value,
    required String displayValue,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: Colors.white54))),
              Text(displayValue, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF00ADB5))),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: Color(0xFF00ADB5),
              inactiveTrackColor: Colors.white10,
              thumbColor: Color(0xFF00ADB5),
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
