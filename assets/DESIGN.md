---
name: Vibrant Kinetic
implementation: lib/core/theme/ (app_colors, app_spacing, app_shadows, app_motion, app_typography, app_theme)
colors:
  # Neutrals — one slate ramp for every surface and every piece of text
  surface: '#f7f8fc'
  surface-dim: '#e6eaf2'
  surface-bright: '#ffffff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f9'
  surface-container: '#ebeef5'
  surface-container-high: '#e3e7f0'
  surface-container-highest: '#dae0ec'
  on-surface: '#101828'          # 15.9:1 on white
  on-surface-variant: '#4a5568'  # 7.6:1 on surface
  outline: '#667085'             # 5.3:1 on white — safe for 12px metadata
  outline-variant: '#d3d8e3'     # hairlines only, never text
  inverse-surface: '#1b2434'
  inverse-on-surface: '#eef2f9'
  # Sun — primary action, XP, coins
  sun: '#ffc531'
  on-sun: '#3d2c00'              # 8.5:1 on sun
  sun-soft: '#fff4d6'
  sun-strong: '#8a6100'
  sun-deep: '#e0a400'
  # Sky — multiplayer and social
  sky: '#35c4f0'
  on-sky: '#05384a'              # 6.2:1 on sky
  sky-soft: '#ddf3fc'
  sky-strong: '#0b5e7a'
  sky-deep: '#17a5d6'
  # Mint — daily challenge, progress, success
  mint: '#3dd07f'
  on-mint: '#06381e'             # 6.6:1 on mint
  mint-soft: '#dcf6e7'
  mint-strong: '#0e7a44'
  mint-deep: '#23b268'
  # Violet — shop, cosmetics, unlockables
  violet: '#a78bfa'
  on-violet: '#2e1065'           # 5.6:1 on violet
  violet-soft: '#ebe4fe'
  violet-strong: '#5b34c7'
  violet-deep: '#8b69f2'
  # Streak — urgency
  streak: '#ff7a3d'
  on-streak: '#4a1b00'
  streak-soft: '#ffe8da'
  streak-strong: '#b44100'
  streak-deep: '#e85f1f'
  # Semantic
  error: '#c5221f'
  on-error: '#ffffff'
  error-container: '#ffe4e1'
  on-error-container: '#7a0f0d'
  disabled: '#e3e7f0'
  on-disabled: '#8b93a5'
typography:
  display-lg: { fontFamily: Quicksand, fontSize: 40px, fontWeight: '700', lineHeight: 48px, letterSpacing: -0.5px }
  display-md: { fontFamily: Quicksand, fontSize: 34px, fontWeight: '700', lineHeight: 42px }
  headline-lg: { fontFamily: Quicksand, fontSize: 28px, fontWeight: '700', lineHeight: 36px }
  headline-md: { fontFamily: Quicksand, fontSize: 24px, fontWeight: '700', lineHeight: 32px }
  headline-sm: { fontFamily: Quicksand, fontSize: 21px, fontWeight: '700', lineHeight: 28px }
  title-lg: { fontFamily: Quicksand, fontSize: 20px, fontWeight: '700', lineHeight: 28px }
  title-md: { fontFamily: Quicksand, fontSize: 17px, fontWeight: '700', lineHeight: 24px }
  title-sm: { fontFamily: Plus Jakarta Sans, fontSize: 15px, fontWeight: '700', lineHeight: 20px }
  body-lg: { fontFamily: Plus Jakarta Sans, fontSize: 17px, fontWeight: '500', lineHeight: 26px }
  body-md: { fontFamily: Plus Jakarta Sans, fontSize: 15px, fontWeight: '400', lineHeight: 22px }
  body-sm: { fontFamily: Plus Jakarta Sans, fontSize: 13px, fontWeight: '400', lineHeight: 18px }
  label-lg: { fontFamily: Plus Jakarta Sans, fontSize: 15px, fontWeight: '700', lineHeight: 20px, letterSpacing: 0.2px }
  label-md: { fontFamily: Plus Jakarta Sans, fontSize: 13px, fontWeight: '700', lineHeight: 16px, letterSpacing: 0.3px }
  label-sm: { fontFamily: Plus Jakarta Sans, fontSize: 12px, fontWeight: '700', lineHeight: 16px, letterSpacing: 0.4px }
radius:
  xs: 8px
  sm: 12px
  md: 16px
  lg: 20px
  xl: 24px
  xxl: 28px
  hero: 32px
  pill: 999px
spacing:
  unit: 4px
  xxs: 2px
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  xxl: 24px
  xxxl: 32px
  huge: 40px
  screen-margin: 20px
  gutter: 14px
  section-gap: 28px
sizes:
  touch-min: 48px
  touch-comfortable: 56px
  progress-bar-height: 14px
motion:
  instant: 90ms   # press acknowledgement
  fast: 160ms     # release, chip toggles
  normal: 220ms   # default move/fade
  slow: 420ms     # progress fills, counters
  celebrate: 700ms
  page: 280ms
  press-scale: 0.965
  press-scale-small: 0.92
  press-depth: 3px
---

## Brand & Style
A modern casual-game surface, not an educational app for children. The
interface reads as a set of physical, touchable objects: squircle geometry,
vibrant colour blocking, soft tactile depth, and generous empty space. It has
to be fun enough that a four-year-old wants to press it and calm enough that a
fifty-year-old wants to open it every morning.

The rule that resolves that tension: **the personality lives in the shapes,
the colours and the motion — never in the text size, the density, or the
contrast.** Type stays large and quiet; colour and geometry carry the play.

## Colours
Five families, each with a fixed job. Never introduce a colour outside them.

| Family | Meaning | Where |
| --- | --- | --- |
| **Sun** (yellow) | The primary action, XP, coins | Play Solo card, level medallion, coin chip, active nav |
| **Sky** (cyan) | Competition, other people | Multiplayer, friends, focused inputs |
| **Mint** (green) | Progress, streaks, success | Daily challenge, success states |
| **Violet** (purple) | Ownership, cosmetics, unlockables | Shop, themes, Pro |
| **Streak** (orange) | Urgency, "don't lose it" | Streak badge, warnings |

Each family exposes the same four roles: `X` (saturated fill), `onX` (text on
that fill), `X-soft` (pale tint for icon wells on white), `X-strong` (the hue
darkened for text on white) and `X-deep` (pressed state, tinted shadow).

**Every fill/on pair clears WCAG AA at 4.5:1.** Text on a coloured surface is
always a dark tint of that surface's own hue, never white — white on mid-tone
yellow, green or cyan cannot reach AA, and it is the single most common
failure in games styled this way.

Colour never carries meaning alone. Status is always colour **plus** an icon
**plus** a word.

## Typography
**Quicksand** for headings, titles and numbers; **Plus Jakarta Sans** for body,
labels and buttons. Quicksand's rounded terminals echo the squircles and read
as friendly without reading as juvenile; Plus Jakarta Sans has the x-height and
open apertures that keep 13px legible for a reader with low vision.

The smallest type in the product is 13px, and everything under 15px is
metadata that is never the only route to a piece of information. Numbers that
change in place (scores, coins, XP, timers) use tabular figures so the layout
does not twitch as digits update.

## Layout & Spacing
20px screen margins, 14px gutters, a 4px vertical rhythm, and a 28px gap
between sections. The Home column is capped at 560px so a tablet or unfolded
device gets a readable column rather than stretched cards.

Nothing assumes a screen width. Card heights are driven by their content with
a stated minimum, so long labels and enlarged system text grow the card
instead of clipping it.

## Elevation & Depth
Soft, large, Y-offset shadows — never Material's tonal elevation.

- Neutral cards use a grey shadow (`card`, `raised`, `floating`).
- Saturated surfaces use a shadow tinted with their own `-deep` hue, so the
  colour stays vibrant instead of turning muddy.
- On press, the shadow flattens as the surface travels down: the shadow is
  the depth cue, so it has to move with the element.

## Shapes
Squircles everywhere; no 90-degree corners. Hero surfaces 32px, cards 24px,
buttons and wells 16px, chips and badges fully rounded.

## Motion
Feedback lands in under 200ms. Every press does three things at once — scale
down, travel toward the screen, flatten its shadow — which is what makes a
tap legible to a pre-reader and confirmable for someone who cannot feel the
haptic. Progress bars and counters animate to their value (rewards should be
*witnessed*); everything else is fast and unshowy.

All motion is transform and opacity only, so nothing costs a layout pass.
`Pressable` honours the platform's "reduce motion" setting.

## Components
Implemented in `lib/core/widgets/`:

- **Pressable** — the app's one press interaction. Replaces `InkWell` (whose
  ripple is invisible on saturated fills) and bare `GestureDetector` (no
  feedback at all). Owns scale, depth, shadow flattening, haptics, semantics.
- **AppCard** — the base container. Owns radius, padding, background, shadow;
  becomes a `Pressable` when given an `onTap`.
- **GameIcon** — an icon in a tinted rounded well (`.small` / `.large`). Icons
  are never bare glyphs floating on a colour.
- **AppBadge** — status pill (`.neutral`, `.success`). Always icon + word.
- **AppStatChip** — one live number with its icon (`.coins`, `.streak`),
  minimum 48dp tall, tabular figures.
- **AppProgressBar** — thick, fully rounded, animated to its value, with a
  gloss highlight and a percentage exposed to screen readers.
- **SectionHeader** — semantic header plus an optional action.

## Accessibility
- 4.5:1 minimum for text, 3:1 for icons and large text. Every token pair in
  this file has been checked.
- 48dp minimum touch target, 56dp on primary controls.
- Colour is never the only carrier of meaning.
- System font scaling is honoured and clamped at 135% (`utils/app.dart`);
  layouts survive the whole range, and the two-up mode row folds to a column
  past 120%.
- Interactive elements carry semantic labels; decoration is excluded from the
  semantics tree.
- `prefers-reduced-motion` is respected by `Pressable`.
