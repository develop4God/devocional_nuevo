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