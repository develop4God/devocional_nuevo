# System Navigation Bar Fix - Proper AppBar Usage

This guide explains how to properly implement `CustomAppBar` with `SystemUiOverlayStyle` to ensure
the system navigation bar is visible across all pages in the app.

## Problem

When using `CustomAppBar` without the proper `AnnotatedRegion<SystemUiOverlayStyle>` wrapper, the
system navigation bar (the bottom navigation bar with back/home/recent buttons on Android) may not
display correctly or may have incorrect colors.

## Solution

### Step 1: Required Imports

Add these imports to your page file:

```dart
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:flutter/services.dart';
```

### Step 2: Wrap Scaffold with AnnotatedRegion

In your page's `build` method, wrap the entire `Scaffold` with
`AnnotatedRegion<SystemUiOverlayStyle>`:

```dart
@override
Widget build(BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: themeState.systemUiOverlayStyle,
    child: Scaffold(
      appBar: CustomAppBar(titleText: 'your.title.key'.tr()),
      body: // ... your body content
    ),
  );
}
```

### Step 3: ThemeBloc Configuration

The `ThemeBloc` must provide the correct `systemUiOverlayStyle`. This should already be configured
in `theme_state.dart`:

```dart
/// Get system UI overlay style for current theme
SystemUiOverlayStyle get systemUiOverlayStyle {
  final iconBrightness =
      brightness == Brightness.dark ? Brightness.light : Brightness.dark;

  return SystemUiOverlayStyle(
    systemNavigationBarColor: themeData.colorScheme.surface,
    // ✅ Uses scaffold background color
    systemNavigationBarIconBrightness: iconBrightness,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
  );
}
```

## Complete Example

```dart
// lib/pages/example_page.dart

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'example.title'.tr()),
        body: Center(
          child: Text('Example Page Content'),
        ),
      ),
    );
  }
}
```

## Pages Already Fixed

The following pages have been updated with the proper pattern:

- ✅ `lib/pages/prayers_page.dart`
- ✅ `lib/pages/favorites_page.dart`
- ✅ `lib/pages/about_page.dart`
- ✅ `lib/pages/contact_page.dart`
- ✅ `lib/pages/settings_page.dart`
- ✅ `lib/pages/backup_settings_page.dart`
- ✅ `lib/pages/application_language_page.dart`
- ✅ `lib/pages/notification_config_page.dart`
- ✅ `lib/pages/bible_reader_page.dart`
- ✅ `lib/pages/devocionales_page.dart`
- ✅ `lib/pages/discovery_detail_page.dart`
- ✅ `lib/pages/discovery_list_page.dart`

## Checklist for New Pages

When creating a new page with `CustomAppBar`, always:

1. [ ] Import `theme_bloc.dart`, `theme_state.dart`, and `services.dart`
2. [ ] Get `themeState` from `context.watch<ThemeBloc>().state as ThemeLoaded`
3. [ ] Wrap `Scaffold` with `AnnotatedRegion<SystemUiOverlayStyle>`
4. [ ] Set `value: themeState.systemUiOverlayStyle`
5. [ ] Test on both light and dark themes

## Benefits

- ✅ Consistent system navigation bar colors across all pages
- ✅ Proper icon brightness for light/dark themes
- ✅ Transparent status bar with correct icon colors
- ✅ Professional, polished user experience

