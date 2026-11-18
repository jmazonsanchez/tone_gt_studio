import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tone_gt_studio/ui/layout/landscape_scaffold.dart';
import 'package:tone_gt_studio/ui/layout/responsive_breakpoints.dart';

void main() {
  group('Landscape Layout & Breakpoints Tests', () {
    test('StageLayoutConfig correctly assigns breakpoints based on screen width', () {
      final compact = StageLayoutConfig.fromSize(700, 360);
      expect(compact.breakpoint, StageBreakpoint.compact);
      expect(compact.isCompact, isTrue);
      expect(compact.leftPanelWidth, 72.0);
      expect(compact.rightPanelWidth, 80.0);

      final medium = StageLayoutConfig.fromSize(1000, 600);
      expect(medium.breakpoint, StageBreakpoint.medium);
      expect(medium.isMedium, isTrue);
      expect(medium.leftPanelWidth, 140.0);
      expect(medium.rightPanelWidth, 165.0);

      final wide = StageLayoutConfig.fromSize(1400, 900);
      expect(wide.breakpoint, StageBreakpoint.wide);
      expect(wide.isWide, isTrue);
      expect(wide.leftPanelWidth, 180.0);
      expect(wide.rightPanelWidth, 210.0);
    });

    testWidgets('LandscapeScaffold renders 3 zones without vertical overflow in 1280x720', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: LandscapeScaffold(
            header: Container(height: 56, key: const Key('header')),
            leftPanelBuilder: (ctx, cfg) => Container(key: const Key('left-panel')),
            centerPanelBuilder: (ctx, cfg) => Container(key: const Key('center-panel')),
            rightPanelBuilder: (ctx, cfg) => Container(key: const Key('right-panel')),
          ),
        ),
      );

      expect(find.byKey(const Key('header')), findsOneWidget);
      expect(find.byKey(const Key('left-panel')), findsOneWidget);
      expect(find.byKey(const Key('center-panel')), findsOneWidget);
      expect(find.byKey(const Key('right-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LandscapeScaffold renders in compact mobile landscape (720x360) without overflow', (tester) async {
      tester.view.physicalSize = const Size(720, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: LandscapeScaffold(
            header: Container(height: 48, key: const Key('compact-header')),
            leftPanelBuilder: (ctx, cfg) => Container(key: const Key('compact-left')),
            centerPanelBuilder: (ctx, cfg) => Container(key: const Key('compact-center')),
            rightPanelBuilder: (ctx, cfg) => Container(key: const Key('compact-right')),
          ),
        ),
      );

      expect(find.byKey(const Key('compact-header')), findsOneWidget);
      expect(find.byKey(const Key('compact-left')), findsOneWidget);
      expect(find.byKey(const Key('compact-center')), findsOneWidget);
      expect(find.byKey(const Key('compact-right')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
