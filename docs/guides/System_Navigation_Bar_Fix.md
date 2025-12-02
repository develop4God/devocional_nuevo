agregar imports de theme state

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';

cubrir todo el app bar con el overlay

@override
Widget build(BuildContext context) {
final ColorScheme colorScheme = Theme.of(context).colorScheme;
final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeState.systemUiOverlayStyle,
        child: Scaffold(
          appBar: CustomAppBar(

pero antes habia que hacer un ajustes en el theme bloc para que devuelva el systemUiOverlayStyle
correcto
/// Get system UI overlay style for current theme
SystemUiOverlayStyle get systemUiOverlayStyle {
final iconBrightness =
brightness == Brightness.dark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      systemNavigationBarColor: themeData.colorScheme.surface,
      // ✅ Usa color del scaffold
      systemNavigationBarIconBrightness: iconBrightness,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
    );