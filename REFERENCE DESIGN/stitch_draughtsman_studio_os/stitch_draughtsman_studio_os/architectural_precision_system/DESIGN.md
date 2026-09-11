---
name: Architectural Precision System
colors:
  surface: '#fbf9fb'
  surface-dim: '#dbd9db'
  surface-bright: '#fbf9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f5'
  surface-container: '#efedef'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e4'
  on-surface: '#1b1b1d'
  on-surface-variant: '#44474d'
  inverse-surface: '#303032'
  inverse-on-surface: '#f2f0f2'
  outline: '#75777e'
  outline-variant: '#c5c6cd'
  surface-tint: '#515f78'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#0d1c32'
  on-primary-container: '#76849f'
  inverse-primary: '#b9c7e4'
  secondary: '#0453cd'
  on-secondary: '#ffffff'
  secondary-container: '#356ee7'
  on-secondary-container: '#fefcff'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#002114'
  on-tertiary-container: '#069669'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#b9c7e4'
  on-primary-fixed: '#0d1c32'
  on-primary-fixed-variant: '#39475f'
  secondary-fixed: '#dae2ff'
  secondary-fixed-dim: '#b2c5ff'
  on-secondary-fixed: '#001848'
  on-secondary-fixed-variant: '#0040a2'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#fbf9fb'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e4'
typography:
  headline-display:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  button-text:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  grid_gutter: 24px
  margin_desktop: 64px
  margin_tablet: 32px
  margin_mobile: 16px
  blueprint_unit: 40px
---

## Brand & Style

This design system embodies the intersection of high-end consumer electronics aesthetics and rigorous engineering software. The brand personality is **Elite, Methodical, and Sophisticated**, catering to architects and engineers who demand both aesthetic beauty and technical functionalism.

The visual style is a hybrid of **Corporate Modern** and **Glassmorphism**, characterized by:
- **Technical Precision:** Use of hairline "construction lines" and grid-aligned elements.
- **Architectural Luxury:** Deep tonal depths and vast whitespace that mirror premium physical studios.
- **Engineered Trust:** A UI that feels "calculated" rather than decorated, using math-based spacing and intentional layering.

## Colors

The palette is anchored by **Deep Midnight Blue**, providing a foundational weight that feels authoritative and professional. **Royal Blue** is utilized exclusively for primary actions and interactive states to maintain a high-contrast focus.

- **Warm White Background:** Used for the base canvas to reduce eye strain and provide a "gallery" feel.
- **Pure White Cards:** Reserved for elevated surfaces to create a crisp, "Apple-like" distinction between the workspace and the background.
- **Blueprint Accents:** Very light blue-grey strokes (#E2E8F0) are used for technical grid lines and separators.

## Typography

The typography strategy prioritizes legibility and technical rigor. **Inter** provides a neutral, modern foundation for the majority of the UI. To reinforce the engineering narrative, **JetBrains Mono** (Technical alternative to standard labels) is used for data points, coordinates, and metadata labels.

- **Display Headlines:** Use tight letter-spacing for a bold, architectural impact.
- **Labels:** Always in uppercase when using the Monospaced font to evoke blueprint notation styles.
- **Hierarchy:** Maintain high contrast between headlines and body text to ensure clear information architecture in data-heavy views.

## Layout & Spacing

The layout utilizes a **Fixed-Fluid Hybrid Grid**. The central workspace remains fluid to accommodate complex CAD/Project views, while navigation and utility panels follow fixed architectural widths.

- **Blueprint Grid:** A subtle background grid (40px increments) is visible in workspace areas, acting as a technical texture.
- **Rhythm:** All spacing must be multiples of 8px. 
- **Margins:** Generous outer margins (64px on desktop) create a "premium" feel, preventing the UI from feeling cluttered despite high data density.

## Elevation & Depth

This system uses **Architectural Layering** rather than traditional drop shadows.
- **Glassmorphism:** Navigation bars and floating tool palettes use a backdrop-filter (blur: 20px) with a 60% white opacity and a 1px white inner border to simulate frosted glass.
- **Soft Elevation:** Elevated cards use a "dual shadow" technique: one sharp 1px stroke (Deep Midnight at 5% opacity) and one very soft, large-radius ambient shadow (Deep Midnight at 3% opacity).
- **Z-Axis Hierarchy:** Background (Warm White) -> Blueprint Grid -> Workspace Cards (Pure White) -> Floating Tools (Glass/Translucent).

## Shapes

The shape language balances "Soft Tech" with "Architectural Rigor." 
- **Large Radius:** Primary containers and cards use **20px-24px** corners (`rounded-xl` and above) to mirror premium hardware design.
- **Small Radius:** Interactive elements like inputs and buttons use **8px** corners to maintain a sense of precision and "tool-like" utility.
- **Technical Lines:** Separators should be 0.5px to 1px wide, using a low-contrast grey to suggest drafting lines.

## Components

### Buttons
- **Primary:** Deep Midnight Blue background with white text. High-gloss finish or subtle 1px inner top border.
- **Secondary:** Transparent with a 1px technical border in Primary color.
- **Tertiary/Ghost:** No border, JetBrains Mono font, used for utility actions.

### Cards
- Always **Pure White** with a 1px border (#E2E8F0).
- Padding should be generous (min 32px) to maintain the "luxurious" spatial feel.

### Input Fields
- Subtle Warm White background to distinguish from the card surface.
- Focus state: 1px Royal Blue border with a 4px soft outer glow.

### Technical Elements
- **Chips:** Small, monospaced text, 4px rounded corners, used for project status and tags.
- **Data Tables:** No vertical borders. Horizontal borders should be "hairline" (0.5px). Headers in JetBrains Mono.

### Footer
The system signature should be placed in the bottom right of the main viewport or footer:
- **Style:** 11px Inter, Light Grey (#94A3B8), regular weight.
- **Content:** "UI/UX Design & Product Experience crafted by PixelMint Studio MVS"