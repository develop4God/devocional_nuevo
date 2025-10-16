import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutlinedButtonTheme Border Color Tests', () {
    test('Deep Purple light theme should have black border', () {
      final theme = appThemeFamilies['Deep Purple']!['light']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.black, reason: 'Light theme should have black border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Deep Purple dark theme should have white border', () {
      final theme = appThemeFamilies['Deep Purple']!['dark']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.white, reason: 'Dark theme should have white border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Green light theme should have black border', () {
      final theme = appThemeFamilies['Green']!['light']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.black, reason: 'Light theme should have black border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Green dark theme should have white border', () {
      final theme = appThemeFamilies['Green']!['dark']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.white, reason: 'Dark theme should have white border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Pink light theme should have black border', () {
      final theme = appThemeFamilies['Pink']!['light']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.black, reason: 'Light theme should have black border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Pink dark theme should have white border', () {
      final theme = appThemeFamilies['Pink']!['dark']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.white, reason: 'Dark theme should have white border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Cyan light theme should have black border', () {
      final theme = appThemeFamilies['Cyan']!['light']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.black, reason: 'Light theme should have black border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Cyan dark theme should have white border', () {
      final theme = appThemeFamilies['Cyan']!['dark']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.white, reason: 'Dark theme should have white border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Light Blue light theme should have black border', () {
      final theme = appThemeFamilies['Light Blue']!['light']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.black, reason: 'Light theme should have black border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('Light Blue dark theme should have white border', () {
      final theme = appThemeFamilies['Light Blue']!['dark']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      
      expect(borderSide, isNotNull, reason: 'OutlinedButtonTheme side should be defined');
      expect(borderSide?.color, Colors.white, reason: 'Dark theme should have white border');
      expect(borderSide?.width, 1.0, reason: 'Border width should be 1.0');
    });

    test('All themes should have border radius of 25', () {
      for (final themeFamily in appThemeFamilies.entries) {
        for (final modeEntry in themeFamily.value.entries) {
          final theme = modeEntry.value;
          final shape = theme.outlinedButtonTheme.style?.shape?.resolve({});
          
          expect(shape, isA<RoundedRectangleBorder>(),
              reason: '${themeFamily.key} ${modeEntry.key} should have RoundedRectangleBorder');
          
          if (shape is RoundedRectangleBorder) {
            expect(shape.borderRadius, BorderRadius.circular(25),
                reason: '${themeFamily.key} ${modeEntry.key} should have border radius of 25');
          }
        }
      }
    });

    test('All themes should match inputDecorationTheme border properties', () {
      for (final themeFamily in appThemeFamilies.entries) {
        for (final modeEntry in themeFamily.value.entries) {
          final theme = modeEntry.value;
          final outlinedButtonBorder = theme.outlinedButtonTheme.style?.side?.resolve({});
          final inputBorder = theme.inputDecorationTheme.border as OutlineInputBorder?;
          
          expect(outlinedButtonBorder, isNotNull,
              reason: '${themeFamily.key} ${modeEntry.key} OutlinedButton should have border');
          expect(inputBorder, isNotNull,
              reason: '${themeFamily.key} ${modeEntry.key} InputDecoration should have border');
          
          if (outlinedButtonBorder != null && inputBorder != null) {
            expect(outlinedButtonBorder.width, inputBorder.borderSide.width,
                reason: '${themeFamily.key} ${modeEntry.key} border widths should match');
            expect(outlinedButtonBorder.color, inputBorder.borderSide.color,
                reason: '${themeFamily.key} ${modeEntry.key} border colors should match');
          }
        }
      }
    });
  });
}
