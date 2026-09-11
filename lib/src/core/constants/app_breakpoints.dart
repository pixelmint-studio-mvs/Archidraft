/// Responsive breakpoints for the ARCHI DRAFT application.
///
/// Used to determine which navigation pattern to display:
/// - Mobile (< 600px): BottomNavigationBar
/// - Tablet (600-1024px): NavigationRail
/// - Desktop (> 1024px): Top horizontal navigation
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this: mobile layout (bottom nav)
  static const double mobile = 600;

  /// Below this: tablet layout (nav rail)
  /// Above this: desktop layout (top nav)
  static const double tablet = 1024;

  /// Max content width for desktop
  static const double maxContentWidth = 1280;

  /// Helper to check if width is mobile
  static bool isMobile(double width) => width < mobile;

  /// Helper to check if width is tablet
  static bool isTablet(double width) => width >= mobile && width < tablet;

  /// Helper to check if width is desktop
  static bool isDesktop(double width) => width >= tablet;
}
