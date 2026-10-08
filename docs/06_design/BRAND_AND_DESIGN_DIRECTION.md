# BRAND AND DESIGN DIRECTION

ARCHI DRAFT visually communicates technical precision, architectural discipline, and professional trust.

**Design Ethos:**
**Professional • Architectural • Technical • Modern • Premium • Trustworthy • Clean**

---

## 1. Design System & Theme Tokens

### A. Color Palette (`AppColors`)
The color system reflects architectural blueprints and modern engineering software:
- **Primary:** Deep slate navy (`#0D1B2A` / `#1B263B`) representing structural stability and authority.
- **Secondary / Accent:** Blueprint cyan (`#00A3FF` / `#0088D4`) used for active indicators, links, and accents.
- **Tertiary:** Amber / Ochre for warnings and review badges (`UNDER_CLIENT_REVIEW`).
- **Surfaces & Containers:** Neutral, high-contrast dark/light container tiers with subtle borders (`outlineVariant` at 20–30% opacity).

### B. Typography (`AppTypography`)
- **Headers:** Clean, sharp geometric sans-serif for high legibility on high-density engineering dashboards.
- **Technical Labels:** Monospace styling (`AppTypography.labelMono`) used for file sizes, timestamps, drawing versions, and status indicators.
- **Body:** Neutral sans-serif optimized for long-form project descriptions and revision notes.

### C. Spacing & Grid (`AppSpacing`)
- Strict 4px/8px modular grid:
  - `xs`: 4px
  - `sm`: 8px
  - `md`: 12px
  - `lg`: 16px
  - `xl`: 24px
  - `xxl`: 32px
- Consistent corner radii: Small to medium curves (`radiusDefault`: 8px, `radiusLg`: 12px, `radiusXl`: 16px) avoiding playful, overly rounded shapes.

---

## 2. Implemented Visual Components

- **`BlueprintBackground`:** Subtle architectural grid background reinforcing technical identity.
- **`GlassCard`:** Translucent container with soft borders and delicate shadows.
- **`ProjectStatusChip`:** Compact, color-coded badge mapping cleanly across all 8 project states.
- **`FileAttachmentCard`:** Structured file item with technical metadata, format icon, and inline Open/Download/Delete actions.
- **`CollaborationHub`:** Clean technical messaging layout with sender role badges, timestamp formatting, and inline attachment previews based on the Stitch design system.
