import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import 'effect_detail_modal.dart';

/// Interactive Memory Edit / Signal Chain Widget for Boss GT-1B.
/// Replicates the hardware [MEMORY EDIT] button and the signal routing chain
/// ([INPUT] -> [PEDAL FX] -> [COMP] -> [OD/DS] -> [PREAMP] -> [FX1] -> [FX2] -> [DELAY] -> [REV] -> [OUTPUT]).
class MemoryEditChainBar extends StatefulWidget {
  final List<EffectBlock> effects;
  final Function(EffectBlock effect) onToggle;
  final Function(int fromIndex, int toIndex) onMoveEffect;
  final VoidCallback? onToggleMemoryEdit;
  final bool isExpanded;

  const MemoryEditChainBar({
    super.key,
    required this.effects,
    required this.onToggle,
    required this.onMoveEffect,
    this.onToggleMemoryEdit,
    this.isExpanded = true,
  });

  @override
  State<MemoryEditChainBar> createState() => _MemoryEditChainBarState();
}

class _MemoryEditChainBarState extends State<MemoryEditChainBar> {
  int? _selectedBlockIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: MEMORY EDIT Button & Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Authentic GT-1B MEMORY EDIT illuminated badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1C0E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF9800), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alt_route, size: 14, color: Color(0xFFFF9800)),
                      SizedBox(width: 6),
                      Text(
                        'MEMORY EDIT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF9800),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'FX CHAIN • LÍNEA DE CONEXIÓN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(
                  '${widget.effects.where((e) => e.isEnabled).length}/${widget.effects.length} ON',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // 2. Horizontal Signal Chain Route
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: widget.effects.length + 2, // +2 for INPUT and OUTPUT
              itemBuilder: (context, index) {
                // First: Input Jack
                if (index == 0) {
                  return _buildTerminalNode(
                    title: 'INPUT',
                    icon: Icons.music_note,
                    color: const Color(0xFF00ADB5),
                    subtitle: 'BASS IN',
                  );
                }

                // Last: Output Jack
                if (index == widget.effects.length + 1) {
                  return _buildTerminalNode(
                    title: 'OUTPUT',
                    icon: Icons.speaker,
                    color: const Color(0xFF4CAF50),
                    subtitle: 'AMP / PA',
                  );
                }

                // Intermediate Effect Block Node
                final effectIndex = index - 1;
                final effect = widget.effects[effectIndex];
                final isSelected = _selectedBlockIndex == effectIndex;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Signal Cable Arrow Connector
                    _buildCableConnector(isActive: effect.isEnabled),

                    // Effect Block Card in Chain
                    _buildChainBlock(
                      effect: effect,
                      index: effectIndex,
                      isSelected: isSelected,
                      isFirst: effectIndex == 0,
                      isLast: effectIndex == widget.effects.length - 1,
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Chain Helper Footer Hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0E0E16),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app, size: 12, color: Colors.white38),
                    SizedBox(width: 4),
                    Text(
                      'Toca para conmutar ON/OFF • Usa ◀ / ▶ para cambiar el orden',
                      style: TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ],
                ),
                Text(
                  'ROUTING: SERIE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF9800).withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the INPUT and OUTPUT termination jacks of the signal chain
  Widget _buildTerminalNode({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: 66,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 8, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  /// Builds the animated cable segment between effect blocks
  Widget _buildCableConnector({required bool isActive}) {
    return Container(
      width: 22,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 3,
            color: isActive ? const Color(0xFF00ADB5) : Colors.white12,
          ),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: isActive ? Colors.white : Colors.white24,
          ),
        ],
      ),
    );
  }

  /// Builds an interactive stompbox node on the signal chain
  Widget _buildChainBlock({
    required EffectBlock effect,
    required int index,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
  }) {
    final active = effect.isEnabled;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBlockIndex = (_selectedBlockIndex == index) ? null : index;
        });
        widget.onToggle(effect);
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => EffectDetailModal(effect: effect),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 82,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF222230) : const Color(0xFF181822),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? effect.accentColor
                : (isSelected ? const Color(0xFFFF9800) : Colors.white12),
            width: active ? 1.6 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: effect.accentColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Jewel LED & Status Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? effect.accentColor : Colors.black87,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: effect.accentColor,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  active ? 'ON' : '..',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: active ? effect.accentColor : Colors.white24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Effect Name Badge
            Text(
              effect.name,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : Colors.white38,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 4),

            // Left / Right Reordering Controls (Knob 2 Simulator)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Move Left (Earlier in signal chain)
                InkWell(
                  onTap: isFirst ? null : () => widget.onMoveEffect(index, index - 1),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.arrow_left,
                      size: 16,
                      color: isFirst ? Colors.white12 : const Color(0xFFFF9800),
                    ),
                  ),
                ),

                // Order Index Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white60,
                    ),
                  ),
                ),

                // Move Right (Later in signal chain)
                InkWell(
                  onTap: isLast ? null : () => widget.onMoveEffect(index, index + 1),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: isLast ? Colors.white12 : const Color(0xFFFF9800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
