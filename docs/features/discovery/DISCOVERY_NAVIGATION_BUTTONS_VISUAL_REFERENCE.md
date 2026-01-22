# Discovery Navigation Buttons - Visual Reference

## Button Layout Overview

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                 STUDY CONTENT                       │
│                                                     │
│                     (Card)                          │
│                                                     │
│                                                     │
│                                                     │
│  ┌──────────────────┐   ┌──────────────────┐      │
│  │  ← Previous      │   │      Next →      │      │  ← Slice 2-4
│  └──────────────────┘   └──────────────────┘      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Button States by Slice Position

### First Slice (1/5)

```
┌─────────────────────────────────────────────────────┐
│                   Study Title                       │
│                                                     │
│  [Empty Space]           ┌──────────────────┐      │
│                          │      Next →      │      │
│                          └──────────────────┘      │
└─────────────────────────────────────────────────────┘
```

- **Left**: Empty (no Previous button)
- **Right**: Next button (Filled, Primary color)

### Middle Slices (2/5, 3/5, 4/5)

```
┌─────────────────────────────────────────────────────┐
│                   Study Title                       │
│                                                     │
│  ┌──────────────────┐   ┌──────────────────┐      │
│  │  ← Previous      │   │      Next →      │      │
│  └──────────────────┘   └──────────────────┘      │
└─────────────────────────────────────────────────────┘
```

- **Left**: Previous button (Outlined, Primary border)
- **Right**: Next button (Filled, Primary color)

### Last Slice (5/5)

```
┌─────────────────────────────────────────────────────┐
│                   Study Title                       │
│                                                     │
│  ┌──────────────────┐   ┌──────────────────┐      │
│  │  ← Previous      │   │   ✓ Exit         │      │
│  └──────────────────┘   └──────────────────┘      │
└─────────────────────────────────────────────────────┘
```

- **Left**: Previous button (Outlined, Primary border)
- **Right**: Exit button (Filled, Primary color, check icon)

## Button Specifications

### Previous Button (Outlined Style)

```dart
OutlinedButton.icon
(
height: 48px
background: surface color with 95% opacity
border: primary color with 30% opacity, 1.5px width
border-radius: 24px
icon: arrow_back_ios_rounded (16px)
text: "Previous" / "Anterior" / etc.
font-size: 14px
font-weight: 600 (semibold)
color: primary
padding: 16px horizontal
)
```

### Next Button (Filled Style)

```dart
FilledButton.icon
(
height: 48px
background: primary color
foreground: onPrimary color
border-radius: 24px
icon: arrow_forward_ios_rounded (16px, at end)
text: "Next" / "Siguiente" / etc.
font-size: 14px
font-weight: 600 (
semibold
)
padding
:
16
px
horizontal
)
```

### Exit Button (Filled Style)

```dart
FilledButton.icon
(
height: 48px
background: primary color
foreground: onPrimary color
border-radius: 24px
icon: check_circle_outline_rounded (18px)
text: "Exit" / "Salir" / etc.
font-size: 14px
font-weight: 600 (semibold)
padding
:
16
px
horizontal
)
```

## Positioning Details

```
Positioned(
  left: 0
  right: 0
  bottom: 0
  padding: 20px (left/right), 16px (top), 24px (bottom)
)

Row(
  mainAxisAlignment: spaceBetween
  
  [Previous Button]  [8px gap]  [Next/Exit Button]
       (Expanded)                    (Expanded)
)
```

## Color Schemes

### Light Theme

- **Primary Button Background**: Primary color (typically blue/purple)
- **Primary Button Text**: White
- **Outlined Button Border**: Primary color with 30% opacity
- **Outlined Button Text**: Primary color
- **Outlined Button Background**: Surface color with 95% opacity (nearly white)

### Dark Theme

- **Primary Button Background**: Primary color (adjusted for dark mode)
- **Primary Button Text**: White
- **Outlined Button Border**: Primary color with 30% opacity
- **Outlined Button Text**: Primary color
- **Outlined Button Background**: Surface color with 95% opacity (nearly black)

## Interaction States

### Normal State

- Full opacity
- Normal elevation

### Pressed State

- Material ripple effect
- Slight scale animation (built-in to Material buttons)

### Disabled State

- Not applicable (buttons are always enabled)

## Animations

### Page Transition

```dart
duration: 350
ms
curve: easeInOut
```

### Button Appearance

- Buttons only appear on the active/current slice
- Fade in/out handled by parent AnimatedContainer
- No individual button animation

## Accessibility Features

1. **Touch Target**: 48px height meets minimum accessibility requirements
2. **Visual Indicators**: Clear icons show direction
3. **Text Labels**: Localized text for all buttons
4. **Color Contrast**: Primary color provides good contrast with background
5. **Semantic Structure**: Proper button widgets with semantic meaning

## Multi-Language Support

| Language   | Previous  | Next      | Exit    |
|------------|-----------|-----------|---------|
| English    | Previous  | Next      | Exit    |
| Spanish    | Anterior  | Siguiente | Salir   |
| Portuguese | Anterior  | Próximo   | Sair    |
| French     | Précédent | Suivant   | Quitter |
| Japanese   | 前へ        | 次へ        | 終了      |

## Layout Behavior

### Small Screens (< 360px)

- Buttons scale proportionally
- Text remains readable at 14px
- Maintains 48px height for accessibility

### Medium Screens (360px - 600px)

- Optimal button size
- Comfortable spacing

### Large Screens (> 600px)

- Buttons maintain fixed size
- Additional padding for cards provides natural spacing

### Tablet/Landscape

- Buttons scale with card width
- Maintains aspect ratio and readability

## Z-Index Layering

From bottom to top:

1. Card content (SingleChildScrollView)
2. Bottom scrim gradient (IgnorePointer)
3. **Navigation buttons** (Interactive)
4. Celebration overlay (IgnorePointer, when active)

This ensures buttons are always tappable and visible above the content gradient.
