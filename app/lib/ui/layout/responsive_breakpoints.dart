enum StageBreakpoint {
  compact, // Mobile landscape (< 750px)
  medium,  // Tablet landscape / small laptop (750px - 1149px)
  wide,    // Wide desktop / large tablet (>= 1150px)
}

class StageLayoutConfig {
  final StageBreakpoint breakpoint;
  final double screenWidth;
  final double screenHeight;

  const StageLayoutConfig({
    required this.breakpoint,
    required this.screenWidth,
    required this.screenHeight,
  });

  factory StageLayoutConfig.fromSize(double width, double height) {
    StageBreakpoint bp;
    if (width < 750) {
      bp = StageBreakpoint.compact;
    } else if (width < 1150) {
      bp = StageBreakpoint.medium;
    } else {
      bp = StageBreakpoint.wide;
    }
    return StageLayoutConfig(
      breakpoint: bp,
      screenWidth: width,
      screenHeight: height,
    );
  }

  bool get isCompact => breakpoint == StageBreakpoint.compact;
  bool get isMedium => breakpoint == StageBreakpoint.medium;
  bool get isWide => breakpoint == StageBreakpoint.wide;

  double get leftPanelWidth {
    switch (breakpoint) {
      case StageBreakpoint.compact:
        return 72.0;
      case StageBreakpoint.medium:
        return 140.0;
      case StageBreakpoint.wide:
        return 180.0;
    }
  }

  double get rightPanelWidth {
    switch (breakpoint) {
      case StageBreakpoint.compact:
        return 80.0;
      case StageBreakpoint.medium:
        return 165.0;
      case StageBreakpoint.wide:
        return 210.0;
    }
  }
}
