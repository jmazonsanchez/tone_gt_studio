import 'package:flutter/material.dart';
import '../../models/effect_block.dart';
import '../layout/responsive_breakpoints.dart';

class StageLeftPanel extends StatelessWidget {
  final List<EffectBlock> effects;
  final Function(EffectBlock) onToggle;
  final VoidCallback? onSelectMaster;
  final StageBreakpoint breakpoint;

  const StageLeftPanel({
    super.key,
    required this.effects,
    required this.onToggle,
    this.onSelectMaster,
    required this.breakpoint,
  });

  @override
  Widget build(BuildContext context) {
    // 12 front panel physical blocks of Boss GT-1B
    final panelEffects = effects.where((e) =>
      e.category == EffectCategory.comp ||
      e.category == EffectCategory.odDs ||
      e.category == EffectCategory.preamp ||
      e.category == EffectCategory.eq ||
      e.category == EffectCategory.fx1 ||
      e.category == EffectCategory.fx2 ||
      e.category == EffectCategory.delay ||
      e.category == EffectCategory.reverb ||
      e.category == EffectCategory.pedalFx ||
      e.category == EffectCategory.footVolume ||
      e.category == EffectCategory.noiseSuppressor
    ).toList();

    final isCompact = breakpoint == StageBreakpoint.compact;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        border: Border(right: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (!isCompact)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.radio_button_checked, size: 11, color: Colors.redAccent),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'BOTONES FÍSICOS',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Buttons Grid/List (Fits without vertical scroll)
          Expanded(
            child: isCompact
                ? _buildCompactList(panelEffects)
                : _buildTwoColumnGrid(panelEffects),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnGrid(List<EffectBlock> panelEffects) {
    // 11 effect blocks + 1 Master button = 12 buttons (2x6 grid)
    final totalCount = panelEffects.length + 1;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.6,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < panelEffects.length) {
          return _buildSiliconeButton(panelEffects[index], isMini: false);
        }
        return _buildMasterButton(isMini: false);
      },
    );
  }

  Widget _buildCompactList(List<EffectBlock> panelEffects) {
    final totalCount = panelEffects.length + 1;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: totalCount,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index < panelEffects.length) {
          return _buildSiliconeButton(panelEffects[index], isMini: true);
        }
        return _buildMasterButton(isMini: true);
      },
    );
  }

  Widget _buildMasterButton({required bool isMini}) {
    return InkWell(
      onTap: onSelectMaster,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1710),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFFF9800),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.25),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF9800),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF9800),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'MASTER',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMini ? 8 : 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiliconeButton(EffectBlock effect, {required bool isMini}) {
    final active = effect.isEnabled;
    final label = _formatButtonLabel(effect.category);

    return InkWell(
      onTap: () => onToggle(effect),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF221114) : const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.redAccent : Colors.black87,
            width: active ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Micro LED indicator
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.redAccent : const Color(0xFF333333),
                boxShadow: [
                  if (active)
                    const BoxShadow(
                      color: Colors.redAccent,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            // Button Label
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMini ? 8 : 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: active ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatButtonLabel(EffectCategory cat) {
    switch (cat) {
      case EffectCategory.comp:
        return 'COMP';
      case EffectCategory.odDs:
        return 'OD/DS';
      case EffectCategory.preamp:
        return 'PREAMP';
      case EffectCategory.eq:
        return 'EQ';
      case EffectCategory.fx1:
        return 'FX1';
      case EffectCategory.fx2:
        return 'FX2';
      case EffectCategory.delay:
        return 'DELAY';
      case EffectCategory.reverb:
        return 'REVERB';
      case EffectCategory.pedalFx:
        return 'PEDAL FX';
      case EffectCategory.footVolume:
        return 'FOOT VOL';
      case EffectCategory.noiseSuppressor:
        return 'N.SUPR';
      default:
        return cat.name.toUpperCase();
    }
  }
}
