import 'package:flutter/material.dart';
import '../../services/patch_service.dart';

/// Real-time Interactive Chromatic Tuner Modal for Boss GT-1B.
/// Driven by live pitch stream (7F 00 05 00) and SysEx Tuner Mode (7F 00 00 02).
class TunerModal extends StatelessWidget {
  final PatchService patchService;
  final VoidCallback onClose;

  const TunerModal({
    super.key,
    required this.patchService,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sys = patchService.systemSettings;
    final note = sys.liveNote;
    final cents = sys.liveCents;
    final inTune = sys.inTune;

    final accentColor = inTune
        ? const Color(0xFF00FF88)
        : (cents.abs() <= 15 ? const Color(0xFF00ADB5) : const Color(0xFFFF9800));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header with Title and Settings
          _buildHeader(),
          const SizedBox(height: 12),

          // 2. Quick Pitch & Output Selector Bar
          _buildTunerConfigRow(sys),
          const SizedBox(height: 16),

          // 3. Central Large Note Display
          _buildNoteDisplay(note, inTune, accentColor),
          const SizedBox(height: 6),

          // Cents deviation text
          Text(
            note == '---'
                ? 'Toca una cuerda para afinar'
                : (inTune ? '¡AFINADO PERFECTO!' : '${cents > 0 ? "+$cents" : "$cents"} cents'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: inTune ? const Color(0xFF00FF88) : Colors.white70,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          // 4. Cent Deviation Gauge / Needle
          _buildCentGauge(cents, inTune, accentColor),
          const SizedBox(height: 8),

          // Gauge Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('♭ BEMOL (-50)', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
              Text('EN TONO (0)', style: TextStyle(fontSize: 11, color: Color(0xFF00FF88), fontWeight: FontWeight.w900)),
              Text('SOSTENIDO (+50) ♯', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Exit Tuner Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('SALIR DEL AFINADOR (MODO PLAY)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ADB5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFF00ADB5), size: 20),
            SizedBox(width: 8),
            Text(
              'AFINADOR CROMÁTICO EN VIVO',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.1, color: Colors.white),
            ),
          ],
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: Colors.white60),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildTunerConfigRow(dynamic sys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Reference Pitch Dropdown (435..445 Hz)
          Expanded(
            child: Row(
              children: [
                const Text('PITCH: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: sys.tunerPitch.clamp(0, 10),
                      isDense: true,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 11),
                      items: List.generate(11, (idx) {
                        return DropdownMenuItem(value: idx, child: Text('${435 + idx} Hz'));
                      }),
                      onChanged: (val) {
                        if (val != null) patchService.updateSystemParameter('tuner_pitch', val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 20, color: Colors.white10),
          const SizedBox(width: 10),
          // Output Mode (Mute / Bypass / Thru)
          Expanded(
            child: Row(
              children: [
                const Text('SALIDA: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: sys.tunerOutput.clamp(0, 2),
                      isDense: true,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Color(0xFF00ADB5), fontWeight: FontWeight.bold, fontSize: 11),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('MUTE')),
                        DropdownMenuItem(value: 1, child: Text('BYPASS')),
                        DropdownMenuItem(value: 2, child: Text('THRU')),
                      ],
                      onChanged: (val) {
                        if (val != null) patchService.updateSystemParameter('tuner_output', val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteDisplay(String note, bool inTune, Color accentColor) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.1),
        border: Border.all(color: accentColor, width: inTune ? 3 : 2),
        boxShadow: inTune
            ? [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 18, spreadRadius: 3)]
            : null,
      ),
      child: Center(
        child: Text(
          note,
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: accentColor,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCentGauge(int cents, bool inTune, Color accentColor) {
    // cents: -50..+50 -> normalized 0.0..1.0
    final normalized = ((cents + 50) / 100).clamp(0.0, 1.0);

    return Container(
      height: 20,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needleX = (constraints.maxWidth - 12) * normalized;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Center in-tune tick mark
              Center(
                child: Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Needle
              Positioned(
                left: needleX,
                child: Container(
                  width: 12,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
