import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../theme/app_theme.dart';
import 'chain_block_chip.dart';

/// Minimalist Signal Chain Widget for Boss GT-1B.
/// Replicates the hardware signal routing with a single continuous rail:
/// [INPUT] ─────── [9 Draggable Stompboxes] ─────── [OUTPUT]
class MemoryEditChainBar extends StatefulWidget {
  final List<EffectBlock> effects;
  final Function(EffectBlock effect)? onToggle;
  final Function(int fromIndex, int toIndex) onMoveEffect;
  final VoidCallback? onToggleMemoryEdit;
  final VoidCallback? onOpenMaster;
  final VoidCallback? onOpenConfig;
  final int? selectedIndex;
  final Function(int index)? onSelectIndex;
  final bool isExpanded;

  const MemoryEditChainBar({
    super.key,
    required this.effects,
    this.onToggle,
    required this.onMoveEffect,
    this.onToggleMemoryEdit,
    this.onOpenMaster,
    this.onOpenConfig,
    this.selectedIndex,
    this.onSelectIndex,
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
    final colors = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          Divider(height: 1, color: colors.borderSubtle),
          SizedBox(height: 104, child: _buildDraggableChain(colors)),
          _buildFooter(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    final activeCount = widget.effects.where((e) => e.isEnabled).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.isDark ? const Color(0xFF221E18) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.6)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alt_route, size: 12, color: Color(0xFFFF9800)),
                SizedBox(width: 4),
                Text('MEMORY EDIT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFFF9800), letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('CADENA DE EFECTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.8))),
          IconButton(
            icon: Icon(Icons.chevron_left, size: 18, color: colors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: () => _scroll(-180),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: () => _scroll(180),
          ),
          const SizedBox(width: 4),
          Text('$activeCount/${widget.effects.length} ON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDraggableChain(AppColorScheme colors) {
    final railColor = colors.isDark ? const Color(0xFF2C2C3E) : const Color(0xFFCBD5E1);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Línea única continua en el fondo debajo de los bloques
        Positioned(
          left: 20,
          right: 20,
          top: 48,
          child: Container(height: 2.5, decoration: BoxDecoration(borderRadius: BorderRadius.circular(1.5), color: railColor)),
        ),
        // Lista interactiva deslizable
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ReorderableListView.builder(
            scrollController: _scrollController,
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            cacheExtent: 2500,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            proxyDecorator: (child, index, animation) => _buildProxyDecorator(child, index, animation, colors),
            header: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTerminalNode(colors: colors, title: 'INPUT', icon: Icons.input_rounded, color: const Color(0xFF00ADB5), subtitle: 'BASS IN'),
                const SizedBox(width: 8),
              ],
            ),
            footer: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                _buildTerminalNode(
                  colors: colors, title: 'OUTPUT', icon: Icons.tune_rounded, color: const Color(0xFF4CAF50),
                  subtitle: (widget.selectedIndex ?? _selectedBlockIndex) == 999 ? 'MASTER' : 'AMP / PA',
                  isSelected: (widget.selectedIndex ?? _selectedBlockIndex) == 999,
                  onTap: () {
                    setState(() => _selectedBlockIndex = 999);
                    widget.onSelectIndex?.call(999);
                  },
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
              final activeSelected = widget.selectedIndex ?? _selectedBlockIndex;
              final isSelected = activeSelected == index;
              return ReorderableDelayedDragStartListener(
                key: ValueKey(effect.id),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChainBlockChip(
                    effect: effect,
                    index: index,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedBlockIndex = index);
                      widget.onSelectIndex?.call(index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProxyDecorator(Widget child, int index, Animation<double> animation, AppColorScheme colors) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final effect = index < widget.effects.length ? widget.effects[index] : null;
        final glowColor = (effect != null && effect.isEnabled) ? effect.accentColor : const Color(0xFF00ADB5);
        return Transform.scale(
          scale: 1.0 + (0.04 * t),
          child: Material(
            color: Colors.transparent,
            elevation: 4.0 * t,
            shadowColor: Colors.black.withValues(alpha: colors.isDark ? 0.45 : 0.2),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: glowColor.withValues(alpha: colors.isDark ? 0.35 : 0.2), blurRadius: 10 * t, spreadRadius: 1)],
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildTerminalNode({
    required AppColorScheme colors,
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final borderColor = isSelected ? color : color.withValues(alpha: colors.isDark ? 0.4 : 0.5);
    final bgColor = isSelected
        ? color.withValues(alpha: colors.isDark ? 0.22 : 0.12)
        : (colors.isDark ? const Color(0xFF191924) : const Color(0xFFF8FAFC));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 62,
        height: 82,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: colors.isDark ? 0.15 : 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.6)),
            Text(subtitle, style: TextStyle(fontSize: 7, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : colors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF0F0F17) : const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app, size: 11, color: colors.textMuted),
              const SizedBox(width: 5),
              Text('Mantén presionado para reordenar • Toca para seleccionar', style: TextStyle(fontSize: 9, color: colors.textMuted)),
            ],
          ),
          Text('ROUTING: SERIE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFFFF9800).withValues(alpha: 0.7), letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
