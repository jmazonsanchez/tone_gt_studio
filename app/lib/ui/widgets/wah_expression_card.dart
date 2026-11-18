import 'package:flutter/material.dart';

/// Interactive Expression Pedal & WAH Footswitch Widget
/// Models the Boss GT-1B Expression Pedal with Toe Footswitch and filter sweep treadle.
class WahExpressionCard extends StatefulWidget {
  final bool isWahActive;
  final int wahPosition; // 0 to 100
  final VoidCallback onToggleWah;
  final ValueChanged<int> onPositionChanged;

  const WahExpressionCard({
    super.key,
    required this.isWahActive,
    required this.wahPosition,
    required this.onToggleWah,
    required this.onPositionChanged,
  });

  @override
  State<WahExpressionCard> createState() => _WahExpressionCardState();
}

class _WahExpressionCardState extends State<WahExpressionCard> with SingleTickerProviderStateMixin {
  late AnimationController _stompAnim;

  @override
  void initState() {
    super.initState();
    _stompAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _stompAnim.dispose();
    super.dispose();
  }

  void _handleFootswitchTap() {
    _stompAnim.reverse().then((_) => _stompAnim.forward());
    widget.onToggleWah();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isWahActive;
    const accentColor = Colors.deepOrangeAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? accentColor.withValues(alpha: 0.7) : Colors.white12,
          width: active ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (active)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? accentColor : const Color(0xFF33333D),
                      boxShadow: active
                          ? [
                              const BoxShadow(
                                color: accentColor,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PEDAL EXP / FOOTSWITCH WAH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? accentColor.withValues(alpha: 0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? accentColor : Colors.white24, width: 0.8),
                ),
                child: Text(
                  active ? 'WAH ACTIVO' : 'VOLUMEN (BYPASS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: active ? accentColor : Colors.white60,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Body: Toe Switch (left) + Treadle Sweep (right)
          Row(
            children: [
              // 1. Footswitch (Toe Switch)
              GestureDetector(
                onTap: _handleFootswitchTap,
                child: ScaleTransition(
                  scale: _stompAnim,
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFE0E0E0),
                          Color(0xFF8E8E98),
                          Color(0xFF303038),
                        ],
                      ),
                      border: Border.all(color: Colors.black54, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        if (active)
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFF9E9EA8),
                              Color(0xFF484850),
                            ],
                          ),
                          border: Border.all(color: Colors.black45, width: 1.2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                active ? Icons.touch_app : Icons.touch_app_outlined,
                                size: 18,
                                color: active ? accentColor : Colors.black87,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PISAR',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: active ? accentColor : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // 2. Treadle Position Slider (Sweep)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          active ? 'BARRIDO DE FILTRO (WAH)' : 'POSICIÓN DE PEDAL',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        Text(
                          '${widget.wahPosition}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: active ? accentColor : const Color(0xFF00ADB5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 12,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                        activeTrackColor: active ? accentColor : const Color(0xFF00ADB5),
                        inactiveTrackColor: const Color(0xFF242430),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: widget.wahPosition.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (val) {
                          widget.onPositionChanged(val.round());
                        },
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TALÓN (0%)', style: TextStyle(fontSize: 8.5, color: Colors.white38, fontWeight: FontWeight.w600)),
                        Text('PUNTA (100%)', style: TextStyle(fontSize: 8.5, color: Colors.white38, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
