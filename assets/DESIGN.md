---
name: Vibrant Kinetic
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#4d4732'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#7e775f'
  outline-variant: '#d0c6ab'
  surface-tint: '#705d00'
  primary: '#705d00'
  on-primary: '#ffffff'
  primary-container: '#ffd700'
  on-primary-container: '#705e00'
  inverse-primary: '#e9c400'
  secondary: '#00668a'
  on-secondary: '#ffffff'
  secondary-container: '#00bdfd'
  on-secondary-container: '#004964'
  tertiary: '#904d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#ffd1af'
  on-tertiary-container: '#914d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffe16d'
  primary-fixed-dim: '#e9c400'
  on-primary-fixed: '#221b00'
  on-primary-fixed-variant: '#544600'
  secondary-fixed: '#c3e8ff'
  secondary-fixed-dim: '#7ad0ff'
  on-secondary-fixed: '#001e2c'
  on-secondary-fixed-variant: '#004c69'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Quicksand
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.5px
  headline-lg:
    fontFamily: Quicksand
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Quicksand
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-sm:
    fontFamily: Quicksand
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 20px
---

## Brand & Style
The design system embodies a high-energy, playful aesthetic tailored for a modern mobile gaming experience. It merges the structured hierarchy of Material 3 with a "Neo-Pop" cartoon sensibility. The interface is designed to evoke joy, movement, and accessibility, targeting a wide demographic of casual gamers.

The visual style utilizes a "Soft-Tactile" approach: elements appear as physical, touchable objects through the use of squircle geometries, thick strokes, and vibrant color blocking. Motion and interaction should feel bouncy and elastic, reinforcing the arcade narrative through stylized digital illustrations and a complete absence of photographic assets.

## Colors
The palette is centered around "Sunny Yellow" to drive energy and focus. 

- **Primary (Sunny Yellow):** Used for main actions, high-priority buttons, and progress indicators.
- **Secondary (Sky Blue):** Used for navigation elements, selection states, and informational icons.
- **Tertiary (Cheerful Orange):** Reserved for urgent notifications, sale items, or "Level Up" moments.
- **Soft Tones:** Mint Green and Pastel Purple serve as category identifiers and background accents for cards to provide visual variety without overwhelming the user.
- **Backgrounds:** Maintain a Crisp White base to ensure the vibrant accents pop, using subtle off-white (`#F8FAFC`) for nested surfaces and container grouping.

## Typography
The typography system prioritizes legibility with a friendly, rounded character. 

**Quicksand** is used for all headlines to maintain the cartoon-inspired aesthetic. Its rounded terminals mirror the UI's squircle shapes. **Plus Jakarta Sans** is used for body text and labels to provide a clean, modern contrast that remains readable during fast-paced gameplay. 

For mobile-specific scaling, `display-lg` should be reserved for splash screens and big win states. All headlines use bold or semi-bold weights to maintain visual weight against the vibrant background colors.

## Layout & Spacing
This design system utilizes a fluid 4-column grid for mobile, emphasizing generous margins to prevent the UI from feeling cluttered.

- **Grid:** 4 columns on mobile, 8 on tablet.
- **Margins:** 20px side margins ensure content is clear of screen edges and "safe zones."
- **Gutter:** 16px between cards and interactive elements.
- **Rhythm:** All vertical spacing follows a 4px/8px baseline increment to maintain a tight, mathematical harmony.

Layouts should be container-based, utilizing squircles to group related information. Use `lg` (24px) spacing for section headers and `md` (16px) for internal padding within cards.

## Elevation & Depth
Depth is communicated through "Soft-Shadows" rather than traditional Material elevation.

- **Surface Tiers:** Use subtle tonal shifts (White to Off-White) to define nested content.
- **Shadow Style:** Shadows are large, soft, and slightly offset on the Y-axis (e.g., `0px 8px 24px rgba(0, 0, 0, 0.08)`). 
- **Color Tinting:** For primary-colored elements (like a Yellow button), use a warm, tinted shadow (e.g., `rgba(255, 140, 0, 0.2)`) instead of grey to maintain color vibrancy.
- **Active States:** When pressed, elements should shift 2px downward on the Y-axis and reduce shadow blur, simulating a physical "click."

## Shapes
The defining characteristic of the UI is the "Squircle" (smoothed corner). 

- **Containers & Cards:** Use a 24px corner radius for a friendly, chunky feel.
- **Buttons:** Use a 16px corner radius to distinguish them from larger layout containers.
- **Selection Controls:** Checkboxes and small chips should use a 12px radius.

Avoid sharp 90-degree angles entirely. Every edge should feel soft to the touch, reinforcing the playful arcade brand.

## Components
- **Buttons:** Primary buttons use Sunny Yellow with a 2px bottom "border-shadow" of Cheerful Orange to create a 3D effect. Text is bold and centered.
- **Cards:** All cards feature a 24px squircle radius, a white background, and a soft Y-offset shadow. For game-specific cards, use the Secondary or Soft tone colors for a top-border accent.
- **Chips/Badges:** Small, pill-shaped elements with high-contrast backgrounds (Mint Green or Pastel Purple) for difficulty levels or item tags.
- **Input Fields:** Thick 2px outlines using a light-grey neutral, which transition to Sky Blue when focused.
- **Progress Bars:** Thick, rounded tracks with a high-contrast fill and a subtle "gloss" highlight on the top half to simulate a plastic feel.
- **Navigation:** A bottom navigation bar with oversized, floating icons that scale up slightly when active.
- **Illustrations:** Every screen should include at least one stylized digital illustration. These should feature thick lines and no gradients to maintain the "cartoon" aesthetic.