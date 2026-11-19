import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

class LandscapeScaffold extends StatelessWidget {
  final Widget header;
  final Widget? syncProgressBar;
  final Widget Function(BuildContext context, StageLayoutConfig config) leftPanelBuilder;
  final Widget Function(BuildContext context, StageLayoutConfig config) centerPanelBuilder;
  final Widget Function(BuildContext context, StageLayoutConfig config) rightPanelBuilder;

  const LandscapeScaffold({
    super.key,
    required this.header,
    this.syncProgressBar,
    required this.leftPanelBuilder,
    required this.centerPanelBuilder,
    required this.rightPanelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = StageLayoutConfig.fromSize(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                header,
                if (syncProgressBar != null) syncProgressBar!,
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Zone 1: Left Panel (Physical GT-1B silicone buttons)
                      SizedBox(
                        width: config.leftPanelWidth,
                        child: leftPanelBuilder(context, config),
                      ),

                      // Zone 2: Center Panel (Memory Edit chain + boutique pedals)
                      Expanded(
                        child: centerPanelBuilder(context, config),
                      ),

                      // Zone 3: Right Panel (EXP / WAH treadle + Foot Volume meter)
                      SizedBox(
                        width: config.rightPanelWidth,
                        child: rightPanelBuilder(context, config),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
