/// Centralized spacing tokens derived from the Stitch design system.
///
/// Based on an 8px baseline grid as specified in both the Stitch Tailwind config
/// and docs/06_design/BRAND_AND_DESIGN_DIRECTION.md.
class AppSpacing {
  AppSpacing._();

  // ── Base Grid ──
  /// Baseline grid unit (8px)
  static const double base = 8.0;

  /// Half base (4px)
  static const double xs = 4.0;

  /// 1× base (8px)
  static const double sm = 8.0;

  /// 1.5× base (12px)
  static const double md = 12.0;

  /// 2× base (16px)
  static const double lg = 16.0;

  /// 3× base (24px) — grid gutter
  static const double xl = 24.0;

  /// 4× base (32px)
  static const double xxl = 32.0;

  /// 5× base (40px) — blueprint unit
  static const double blueprintUnit = 40.0;

  /// 8× base (64px) — desktop margin
  static const double xxxl = 64.0;

  // ── Margin Tokens ──
  /// Mobile horizontal margin (16px)
  static const double marginMobile = 16.0;

  /// Tablet horizontal margin (32px)
  static const double marginTablet = 32.0;

  /// Desktop horizontal margin (64px)
  static const double marginDesktop = 64.0;

  /// Grid gutter (24px) — gap between grid items
  static const double gridGutter = 24.0;

  // ── Border Radius (Architectural Precision System) ──
  /// Small radius (4px) — chips, badges
  static const double radiusSm = 4.0;

  /// Default radius (8px) — inputs, buttons
  static const double radiusDefault = 8.0;

  /// Medium radius (12px) — cards, bento cells
  static const double radiusMd = 12.0;

  /// Large radius (16px) — prominent cards, modal dialogs
  static const double radiusLg = 16.0;

  /// Extra large radius (24px) — main outer containers, hero panels
  static const double radiusXl = 24.0;

  /// Full/circular radius
  static const double radiusFull = 9999.0;

  // ── Elevation ──
  /// Card architectural shadow
  static const double elevationCard = 4.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  /// App bar height
  static const double appBarHeight = 64.0;
}
