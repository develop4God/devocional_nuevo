# Discovery Navigation Buttons - Architecture Diagram

## Component Hierarchy

```
DiscoveryDetailPage (StatefulWidget)
│
├── Scaffold
│   ├── CustomAppBar
│   │   └── titleText: 'discovery.discovery_studies'.tr()
│   │
│   └── body: BlocBuilder<DiscoveryBloc, DiscoveryState>
│       └── Stack
│           ├── Column
│           │   ├── _buildStudyHeader()
│           │   ├── _buildProgressIndicator()
│           │   └── Expanded
│           │       └── PageView.builder  ← Controls slice navigation
│           │           ├── controller: _pageController
│           │           ├── onPageChanged: (index) => setState(...)
│           │           └── itemBuilder: _buildAnimatedCard()
│           │
│           ├── Positioned (Bottom Scrim)
│           │   └── gradient overlay
│           │
│           └── if (_isCelebrating)
│               └── Lottie celebration animation
│
└── _buildAnimatedCard(study, index, isDark, isLast, isAlreadyCompleted)
    └── AnimatedContainer
        └── Material
            └── Stack
                ├── if (study.cards.isNotEmpty)
                │   └── _buildCardContent()  ← Main content
                │
                ├── else if (study.secciones != null)
                │   └── DiscoverySectionCard()
                │
                └── if (_currentSectionIndex == index)  ← Only on active slice
                    └── _buildNavigationButtons(isFirst, isLast)  ⭐ NEW
```

## Navigation Buttons Component Structure

```
_buildNavigationButtons(isFirst, isLast)
│
└── Positioned
    ├── left: 0
    ├── right: 0
    ├── bottom: 0
    │
    └── Padding (20, 16, 20, 24)
        └── Row
            ├── mainAxisAlignment: spaceBetween
            │
            ├── if (!isFirst)  ← Show from 2nd slice onwards
            │   └── Expanded
            │       └── Padding (right: 8)
            │           └── SizedBox (height: 48)
            │               └── OutlinedButton.icon  ← PREVIOUS
            │                   ├── onPressed: _pageController.previousPage()
            │                   ├── icon: arrow_back_ios_rounded
            │                   ├── label: 'discovery.previous'.tr()
            │                   └── style: outlined + primary border
            │
            ├── else  ← On first slice
            │   └── Expanded
            │       └── SizedBox.shrink()  ← Empty space for balance
            │
            └── Expanded
                └── Padding (left: 8)
                    └── SizedBox (height: 48)
                        └── if (isLast)  ← Last slice only
                            └── FilledButton.icon  ← EXIT
                                ├── onPressed: Navigator.pop()
                                ├── icon: check_circle_outline_rounded
                                ├── label: 'discovery.exit'.tr()
                                └── style: filled + primary background
                            
                            else  ← All other slices
                            └── FilledButton.icon  ← NEXT
                                ├── onPressed: _pageController.nextPage()
                                ├── icon: arrow_forward_ios_rounded
                                ├── label: 'discovery.next'.tr()
                                ├── iconAlignment: end
                                └── style: filled + primary background
```

## State Flow Diagram

```
User Opens Study
        ↓
┌───────────────────┐
│   Slice 1 (1/5)   │
│                   │
│  [empty space]    │  🔵 Next →
│                   │
└───────────────────┘
        ↓ (tap Next or swipe)
┌───────────────────┐
│   Slice 2 (2/5)   │
│                   │
│  ← Previous       │  🔵 Next →
│                   │
└───────────────────┘
        ↓ (tap Next or swipe)
┌───────────────────┐
│   Slice 3 (3/5)   │
│                   │
│  ← Previous       │  🔵 Next →
│                   │
└───────────────────┘
        ↓ (tap Next or swipe)
┌───────────────────┐
│   Slice 4 (4/5)   │
│                   │
│  ← Previous       │  🔵 Next →
│                   │
└───────────────────┘
        ↓ (tap Next or swipe)
┌───────────────────┐
│   Slice 5 (5/5)   │
│                   │
│  ← Previous       │  🔵 Exit
│                   │
└───────────────────┘
        ↓ (tap Exit)
  Back to Study List
```

## Translation System Integration

```
Translation Keys Structure
│
i18n/
├── en.json
│   └── discovery
│       ├── previous: "Previous"
│       ├── next: "Next"
│       └── exit: "Exit"
│
├── es.json
│   └── discovery
│       ├── previous: "Anterior"
│       ├── next: "Siguiente"
│       └── exit: "Salir"
│
├── pt.json
│   └── discovery
│       ├── previous: "Anterior"
│       ├── next: "Próximo"
│       └── exit: "Sair"
│
├── fr.json
│   └── discovery
│       ├── previous: "Précédent"
│       ├── next: "Suivant"
│       └── exit: "Quitter"
│
└── ja.json
    └── discovery
        ├── previous: "前へ"
        ├── next: "次へ"
        └── exit: "終了"

Usage in Code:
├── 'discovery.previous'.tr()  ← Calls easy_localization
├── 'discovery.next'.tr()
└── 'discovery.exit'.tr()
```

## Theme Integration

```
ColorScheme (Light/Dark Theme)
│
├── primary  ← Main brand color
│   ├── Used for: Next/Exit button background
│   ├── Used for: Previous button border
│   └── Used for: Previous button text/icon
│
├── onPrimary  ← Color on top of primary
│   └── Used for: Next/Exit button text/icon
│
└── surface  ← Background color
    └── Used for: Previous button background (95% opacity)

Button Styles:
│
├── Previous (OutlinedButton)
│   ├── background: surface.withValues(alpha: 0.95)
│   ├── border: primary.withValues(alpha: 0.3), 1.5px
│   ├── text/icon: primary
│   └── borderRadius: 24px
│
└── Next/Exit (FilledButton)
    ├── background: primary
    ├── text/icon: onPrimary
    └── borderRadius: 24px
```

## Navigation Flow Control

```
PageController (_pageController)
│
├── previousPage()
│   ├── duration: 350ms
│   ├── curve: easeInOut
│   └── decrements current page index
│
└── nextPage()
    ├── duration: 350ms
    ├── curve: easeInOut
    └── increments current page index

State Management:
│
└── _currentSectionIndex (int)
    ├── Updated by: onPageChanged callback
    ├── Controls: Progress indicator
    ├── Controls: Button visibility
    └── Controls: Active card styling
```

## Responsive Layout Strategy

```
Row Layout:
│
├── mainAxisAlignment: spaceBetween
│
├── Left Side: Expanded
│   ├── if (!isFirst): Previous button
│   └── else: Empty SizedBox.shrink()
│
└── Right Side: Expanded
    ├── if (isLast): Exit button
    └── else: Next button

Screen Size Adaptation:
│
├── Small (< 360px)
│   ├── Expanded widgets scale down
│   ├── Text: 14px (readable)
│   └── Height: 48px (maintained)
│
├── Medium (360-600px)
│   ├── Optimal sizing
│   └── Comfortable spacing
│
└── Large (> 600px)
    ├── Proportional scaling
    └── Centered layout
```

## Z-Index Layering (Stack Order)

```
Bottom to Top:
│
├── Layer 1: Card Content
│   └── SingleChildScrollView
│       └── Study content (text, images, etc.)
│
├── Layer 2: Bottom Scrim (IgnorePointer)
│   └── LinearGradient
│       └── Fades to scaffold background
│
├── Layer 3: Navigation Buttons ⭐ NEW
│   └── Positioned (interactive)
│       └── Row with Previous/Next/Exit
│
└── Layer 4: Celebration Overlay (IgnorePointer, conditional)
    └── Lottie animation
        └── Only when _isCelebrating == true
```

## Event Handling Flow

```
User Interaction:
│
├── Tap Previous Button
│   └── onPressed()
│       └── _pageController.previousPage()
│           └── PageView animates to previous index
│               └── onPageChanged(index)
│                   └── setState(() => _currentSectionIndex = index)
│                       └── UI rebuilds with new button state
│
├── Tap Next Button
│   └── onPressed()
│       └── _pageController.nextPage()
│           └── PageView animates to next index
│               └── onPageChanged(index)
│                   └── setState(() => _currentSectionIndex = index)
│                       └── UI rebuilds with new button state
│
└── Tap Exit Button
    └── onPressed()
        └── Navigator.of(context).pop()
            └── Returns to previous screen (Study List)

Alternative: Swipe Gesture
│
└── User swipes left/right
    └── PageView detects gesture
        └── onPageChanged(index)
            └── setState(() => _currentSectionIndex = index)
                └── UI rebuilds with new button state
```

## Conditional Rendering Logic

```dart
Decision
Tree:

if
(
_currentSectionIndex == index) {
// Only show buttons on active slice

├─ Is this the first slice? (index == 0)
│ ├─ Yes → Hide Previous, Show Next
│ └─ No → Show Previous
│
└─ Is this the last slice? (index == totalSections - 1)
├─ Yes → Show Exit instead of Next
└─ No → Show Next
}
```

## Performance Considerations

```
Optimization Strategies:
│
├── Conditional Rendering
│   └── Buttons only built for active slice
│       └── Reduces widget tree size
│
├── const Constructors
│   ├── const EdgeInsets
│   ├── const Duration
│   └── Minimizes rebuilds
│
├── Stateless Button Widgets
│   └── FilledButton/OutlinedButton don't store state
│
└── Efficient Animations
    ├── 350ms duration (feels responsive)
    └── easeInOut curve (smooth perception)
```

---

## Summary

This architecture diagram shows how the navigation buttons integrate seamlessly into the existing
Discovery detail page structure. The buttons are:

1. **Conditionally rendered** based on slice position
2. **Theme-aware** using ColorScheme
3. **Localized** through easy_localization
4. **Responsive** with Expanded layout
5. **Non-invasive** - overlay on active slice only
6. **Performant** - minimal rebuilds

The implementation maintains all existing functionality (swipe gestures, progress indicator,
completion flow) while adding accessible button navigation for users who prefer or need explicit UI
controls.
