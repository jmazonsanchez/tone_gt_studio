import 'package:flutter/material.dart';

class TunerModal extends StatelessWidget {
  final VoidCallback onClose;

  const TunerModal({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141419),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: Color(0xFF00ADB5)),
                  SizedBox(width: 8),
                  Text(
                    'AFINADOR CROMÁTICO (MUTE)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                  ),
                ],
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'E',
            style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: Color(0xFF00ADB5)),
          ),
          const SizedBox(height: 8),
          const Text(
            '41.2 Hz (Cuerda 4)',
            style: TextStyle(fontSize: 16, color: Colors.white60),
          ),
          const SizedBox(height: 24),
          // Pitch Needle Gauge
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(color: Colors.greenAccent, blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('♭ BEMOL', style: TextStyle(fontSize: 12, color: Colors.white38)),
              Text('EN TONO', style: TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              Text('SOSTENIDO ♯', style: TextStyle(fontSize: 12, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.check),
              label: const Text('SALIR DEL AFINADOR', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ADB5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
