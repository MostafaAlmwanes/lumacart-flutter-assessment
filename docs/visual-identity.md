# LumaCart Visual Identity

## 1. Name and positioning

**LumaCart** — A calm, focused mobile storefront for discovering products and saving carts for later.

## 2. Logo and app-icon concept

The mark combines a softly rounded shopping bag with a single upward light beam. The bag communicates commerce; the beam suggests clarity and discovery. The icon should remain recognizable at 48 px and avoid tiny details.

## 3. Color tokens

| Token | Hex | Use |
|---|---:|---|
| Primary | `#3C4CC7` | Primary actions, selected navigation, focused controls |
| Primary container | `#E0E4FF` | Low-emphasis selected surfaces |
| Secondary | `#5C5F72` | Supporting controls and labels |
| Accent | `#F07A5A` | Cart badge, highlights, restrained emphasis |
| Success | `#1E8E62` | Successful persistence and confirmation |
| Warning | `#A86400` | Stale-cache and recoverable cautions |
| Error | `#BA1A1A` | Errors and destructive actions |
| Surface | `#FCF8FF` | Main app background |
| Surface container | `#F1EDF6` | Cards, fields, skeletons |
| Text primary | `#1B1B1F` | Main copy |
| Text secondary | `#46464F` | Metadata and supporting copy |
| Outline | `#777680` | Borders and dividers |

## 4. Theme tokens

### Light

- `colorSchemeSeed`: Primary `#3C4CC7`
- Background/surface: `#FCF8FF`
- Card surface: `#FFFFFF`
- Elevated surface tint: subtle primary tint only
- Divider: outline at 24% opacity

### Dark, optional

- Primary: `#BCC2FF`
- Primary container: `#24308E`
- Accent: `#FFB49E`
- Surface: `#121318`
- Surface container: `#1E1F25`
- Text primary: `#E4E1E9`
- Text secondary: `#C8C5D0`

The implementation includes a coherent dark theme but follows the device setting rather than adding a separate preference screen.

## 5. Typography

Use the platform-default Material 3 typeface to avoid font licensing and binary-size overhead.

| Role | Size / weight |
|---|---|
| Display | 32 / 700 |
| Page heading | 28 / 700 |
| Section heading | 20 / 700 |
| Card title | 16 / 600 |
| Body | 16 / 400 |
| Supporting body | 14 / 400 |
| Label | 12 / 600 |
| Button | 14 / 700 |
| Price, large | 24 / 800 |
| Price, card | 17 / 800 |

Line height should remain at least 1.25 for headings and 1.4 for body copy.

## 6. Spacing scale

`4, 8, 12, 16, 20, 24, 32, 40, 48` logical pixels.

- 4: icon/text micro-gap
- 8: compact internal gap
- 12: chip and small-card padding
- 16: standard card and screen edge padding
- 24: section separation
- 32+: major visual separation

## 7. Border-radius scale

- Small: 8
- Medium: 12
- Large: 16
- Extra large: 24
- Pill: 999

Product cards use 16; text fields and buttons use 12; modal sheets use 24 on top corners.

## 8. Elevation and shadows

Prefer tonal separation to heavy shadows.

- Resting cards: elevation 0 or 1
- Floating actions and modal sheets: elevation 3
- Pressed/dragged state: elevation 4
- Shadows remain low-opacity and soft; avoid dramatic hovering-tile effects.

## 9. Icon style

Use Material Symbols/Icons Rounded where available. Strokes should feel consistent and simple. Icon-only actions require semantic labels and 48x48 hit areas.

## 10. Product-image treatment

- Catalog cards: white image well, 1:1 aspect ratio, `BoxFit.contain`, 16 px internal padding.
- Product details: 4:3 container, `BoxFit.contain`, 24 px internal padding.
- Never crop product imagery aggressively.
- Use a neutral icon placeholder and preserve layout on failure.
- Actual products always use Fake Store API image URLs.

## 11. Empty/error/offline illustration style

Lightweight vector-like compositions with rounded geometric forms, no text embedded in the art, limited to primary, accent, and neutral surface colors. Illustrations should occupy less than 36% of screen height and leave clear space for localized copy and actions.

## 12. Accessibility rules

- Minimum touch target: 48x48 logical pixels.
- Body text should not fall below 14 px.
- Text and essential icons meet WCAG AA contrast against their surfaces.
- Errors include icon and explanatory text, not color alone.
- Layouts remain usable at 200% text scaling.
- Two-column product grids collapse to one column when card content would be cramped.
- Hero and implicit animations are short and skipped/reduced when `disableAnimations` is true.
- Images receive meaningful semantic labels; decorative illustration semantics are excluded.

## 13. Component inventory

### Primary button

Filled, 48 px minimum height, 12 px radius, clear loading state that preserves width.

### Secondary button

Outlined or tonal, same sizing as primary, used for retry, merge, and non-destructive alternatives.

### Text field

Filled surface-container background, persistent label, inline validation, optional leading icon, visible password control when relevant.

### Search field

Rounded filled field with search icon, clear action, debounced input, and accessible “clear search” label.

### Product card

Image well, category label, two-line title, rating row, price, and whole-card tap target. No nested tiny buttons.

### Category chip

Scrollable filter chip row with “All” first. Selected state uses primary container plus checkmark.

### Price and rating row

Price has strong weight; rating uses star icon, numeric rate, and count with secondary color.

### Quantity stepper

Minus, quantity, plus inside a tonal rounded container. Each control has a 48 px target and semantic label.

### Cart summary card

Item count, subtotal, total, and save action. Total receives the strongest type treatment.

### Empty-state panel

Illustration/icon, concise title, one explanatory sentence, and at most one primary action.

### Error panel

Error icon, plain-language message, optional technical detail hidden from primary copy, and retry action.

### Profile information tile

Leading icon, label, selectable value, and multiline support for address.

### Loading skeleton

Rounded neutral blocks matching final layout. Animation is subtle and disabled when reduced motion is requested.
