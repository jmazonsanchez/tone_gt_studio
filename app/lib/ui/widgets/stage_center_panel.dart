import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../layout/responsive_breakpoints.dart';
import '../theme/app_theme.dart';
import 'effect_editor_panel.dart';
import 'mini_pedal_card.dart';
import 'memory_edit_chain_bar.dart';

class StageCenterPanel extends StatelessWidget {
  final List<EffectBlock> effects;
  final Function(EffectBlock) onToggleEffect;
  final Function(int fromIndex, int toIndex) onMoveEffect;
  final StageBreakpoint breakpoint;

  const StageCenterPanel({
    super.key,
    required this.effects,
    required this.onToggleEffect,
    required this.onMoveEffect,
    required this.breakpoint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Signal Chain Routing Bar (Memory Edit)
          MemoryEditChainBar(
            effects: effects,
            onToggle: onToggleEffect,
            onMoveEffect: onMoveEffect,
          ),

          const SizedBox(height: 8),

          // 2. Boutique Stompboxes Shelf (Zero vertical scroll)
          Expanded(
            child: _buildPedalShelf(context, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildPedalShelf(BuildContext context, AppColorScheme colors) {
    // Stompbox pedal shelf arranged horizontally with smooth horizontal scrolling
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: effects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final effect = effects[index];
          return SizedBox(
            width: 140,
            child: MiniPedalCard(
              effect: effect,
              onToggle: () => onToggleEffect(effect),
              onOpenDetail: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => EffectEditorPanel(effect: effect),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
