import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import 'chain_block_chip.dart';

/// Interactive Memory Edit / Signal Chain Widget for Boss GT-1B.
/// Replicates the hardware [MEMORY EDIT] button and draggable signal routing:
/// [INPUT] -> [PEDAL FX] -> [COMP] -> [OD/DS] -> [PREAMP] -> ... -> [OUTPUT]
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(double delta) {
    if (_scrollController.hasClients) {
      final target = (_scrollController.offset + delta).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF9800).withValues(alpha: 0.08), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white12),
          SizedBox(height: 112, child: _buildDraggableChain()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = widget.effects.where((e) => e.isEnabled).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1C0E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF9800), width: 1.2),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF9800).withValues(alpha: 0.4), blurRadius: 6),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alt_route, size: 13, color: Color(0xFFFF9800)),
                SizedBox(width: 5),
                Text('MEMORY EDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFFF9800), letterSpacing: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('SIGNAL CHAIN • CADENA DE EFECTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.0)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20, color: Color(0xFFFF9800)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Desplazar cadena a la izquierda',
            onPressed: () => _scroll(-180),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFFF9800)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Desplazar cadena a la derecha',
            onPressed: () => _scroll(180),
          ),
          const SizedBox(width: 4),
          Text(
            '$activeCount/${widget.effects.length} ON',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableChain() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 4,
      radius: const Radius.circular(4),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        cacheExtent: 2500,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      header: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTerminalNode(
            title: 'INPUT',
            icon: Icons.input,
            color: const Color(0xFF00ADB5),
            subtitle: 'BASS IN',
          ),
          _buildCableConnector(isActive: true),
        ],
      ),
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTerminalNode(
            title: 'OUTPUT',
            icon: Icons.speaker,
            color: const Color(0xFF4CAF50),
            subtitle: 'AMP / PA',
          ),
        ],
      ),
      itemCount: widget.effects.length,
      onReorder: (int oldIndex, int newIndex) {
        final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
        widget.onMoveEffect(oldIndex, targetIndex);
      },
      itemBuilder: (context, index) {
        final effect = widget.effects[index];
        final isSelected = _selectedBlockIndex == index;
        return ReorderableDelayedDragStartListener(
          key: ValueKey(effect.id),
          index: index,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChainBlockChip(
                effect: effect,
                index: index,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedBlockIndex = (_selectedBlockIndex == index) ? null : index;
                  });
                  widget.onToggle(effect);
                },
              ),
              _buildCableConnector(isActive: effect.isEnabled),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _buildTerminalNode({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: 60,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 7, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildCableConnector({required bool isActive}) {
    return SizedBox(
      width: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            color: isActive ? const Color(0xFF00ADB5) : Colors.white12,
          ),
          Icon(
            Icons.chevron_right,
            size: 12,
            color: isActive ? const Color(0xFF00ADB5) : Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
              Icon(Icons.swipe, size: 11, color: Colors.white38),
              SizedBox(width: 5),
              Text(
                'Arrastra para reordenar la cadena • Toca para conmutar ON/OFF',
                style: TextStyle(fontSize: 9, color: Colors.white38),
              ),
            ],
          ),
          Text(
            'ROUTING: SERIE',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF9800).withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
