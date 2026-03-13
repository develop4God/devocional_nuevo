import 'dart:async';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/main.dart';
import 'package:devocional_nuevo/pages/encounters_list_page.dart';
import 'package:devocional_nuevo/pages/prayer_wall_page.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Deep link handler service for Firebase In-App Messaging and other deep links
///
/// Supported deep link patterns:
/// - devocional://devotional/{date} - Navigate to specific devotional
/// - devocional://progress - Navigate to progress page
/// - devocional://prayers - Navigate to prayers page
/// - devocional://prayer_wall - Navigate to prayer wall page
/// - devocional://testimonies - Navigate to testimonies page
/// - devocional://supporter - Navigate to supporter page
/// - devocional://encounters - Navigate to encounters list page
/// - devocional://encounter/{id} - Navigate to specific encounter
/// - devocional://encounter_detail/{id} - Navigate to specific encounter
class DeepLinkHandler {
  static const String scheme = 'devocional';
  static const MethodChannel _channel =
      MethodChannel('com.develop4god.devocional/deeplink');

  /// Initialize deep link handling
  Future<void> initialize() async {
    developer.log(
      'DeepLinkHandler initialized',
      name: 'DeepLinkHandler',
    );

    // Set up method call handler for iOS and for receiving deep links while app is running
    _channel.setMethodCallHandler(_handleMethodCall);

    // Check if app was launched from a deep link (Android)
    try {
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        developer.log(
          'App launched with deep link: $initialLink',
          name: 'DeepLinkHandler',
        );
        await _processDeepLink(initialLink);
      }
    } catch (e) {
      developer.log(
        'Error getting initial link: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
    }
  }

  /// Handle method calls from iOS and Android (for deep links while app is running)
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'handleDeepLink') {
      final String? link = call.arguments as String?;
      if (link != null) {
        await _processDeepLink(link);
      }
    } else if (call.method == 'onDeepLinkReceived') {
      // Handle deep link received while app is already running (Android)
      final String? link = call.arguments as String?;
      if (link != null) {
        developer.log(
          'Deep link received while app running: $link',
          name: 'DeepLinkHandler',
        );
        await _processDeepLink(link);
      }
    }
  }

  /// Process deep link string
  Future<void> _processDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      await handleDeepLink(uri);
    } catch (e) {
      developer.log(
        'Error parsing deep link: $link',
        name: 'DeepLinkHandler',
        error: e,
      );
    }
  }

  /// Handle incoming deep link URI
  Future<bool> handleDeepLink(Uri uri) async {
    developer.log(
      'Handling deep link: ${uri.toString()}',
      name: 'DeepLinkHandler',
    );

    if (uri.scheme != scheme) {
      developer.log(
        'Invalid scheme: ${uri.scheme}, expected: $scheme',
        name: 'DeepLinkHandler',
      );
      return false;
    }

    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
      developer.log(
        'Navigator context is null, cannot navigate',
        name: 'DeepLinkHandler',
      );
      return false;
    }

    // Extract route from host or path segments
    // URIs like "devocional://devotional" have "devotional" as the host
    // URIs like "devocional://devotional/date" have path segments
    String? route = uri.host.isNotEmpty ? uri.host : null;

    if (route == null || route.isEmpty) {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) {
        developer.log(
          'Empty route',
          name: 'DeepLinkHandler',
        );
        return false;
      }
      route = pathSegments.first;
    }

    try {
      switch (route) {
        case 'devotional':
          return await _handleDevotionalDeepLink(
              context, uri.pathSegments, uri.queryParameters);
        case 'progress':
          return await _handleProgressDeepLink(context);
        case 'prayers':
          return await _handlePrayersDeepLink(context);
        case 'prayer_wall':
          return await _handlePrayerWallDeepLink(context);
        case 'testimonies':
          return await _handleTestimoniesDeepLink(context);
        case 'supporter':
          return await _handleSupporterDeepLink(context);
        case 'encounters':
          return await _handleEncountersDeepLink(context);
        case 'encounter':
        case 'encounter_detail':
          return await _handleEncounterDetailDeepLink(
              context, uri.pathSegments);
        default:
          developer.log(
            'Unknown route: $route',
            name: 'DeepLinkHandler',
          );
          return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error handling deep link',
        name: 'DeepLinkHandler',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Handle devotional deep link
  /// Format: devocional://devotional/{date}?action=read
  Future<bool> _handleDevotionalDeepLink(
    BuildContext context,
    List<String> pathSegments,
    Map<String, String> queryParams,
  ) async {
    // For now, just navigate to the main devotional page
    // In the future, this could navigate to a specific date
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
    }

    developer.log(
      'Navigated to devotional page',
      name: 'DeepLinkHandler',
    );

    return true;
  }

  /// Handle progress deep link
  /// Format: devocional://progress
  Future<bool> _handleProgressDeepLink(BuildContext context) async {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
    }

    // Navigate to progress tab (index 1 in bottom navigation)
    // This would need to be integrated with the actual bottom navigation controller
    developer.log(
      'Navigated to progress page',
      name: 'DeepLinkHandler',
    );

    return true;
  }

  /// Handle prayers deep link
  /// Format: devocional://prayers
  Future<bool> _handlePrayersDeepLink(BuildContext context) async {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
    }

    // Navigate to prayers tab (index 2 in bottom navigation)
    developer.log(
      'Navigated to prayers page',
      name: 'DeepLinkHandler',
    );

    return true;
  }

  /// Handle prayer wall deep link
  /// Format: devocional://prayer_wall
  Future<bool> _handlePrayerWallDeepLink(BuildContext context) async {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      // Push PrayerWallPage (don't await - allows function to return immediately)
      final route = MaterialPageRoute(
        builder: (_) => const PrayerWallPage(),
      );
      Navigator.of(context).push(route);

      developer.log(
        'Navigated to prayer wall page',
        name: 'DeepLinkHandler',
      );

      return true;
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
      return false;
    }
  }

  /// Handle testimonies deep link
  /// Format: devocional://testimonies
  Future<bool> _handleTestimoniesDeepLink(BuildContext context) async {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
    }

    // Navigate to testimonies tab (index 3 in bottom navigation)
    developer.log(
      'Navigated to testimonies page',
      name: 'DeepLinkHandler',
    );

    return true;
  }

  /// Handle supporter deep link
  /// Format: devocional://supporter
  Future<bool> _handleSupporterDeepLink(BuildContext context) async {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      // Push SupporterPage to navigator
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SupporterPage()),
      );

      developer.log(
        'Navigated to supporter page',
        name: 'DeepLinkHandler',
      );

      return true;
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
      return false;
    }
  }

  /// Handle encounters list deep link
  /// Format: devocional://encounters
  Future<bool> _handleEncountersDeepLink(BuildContext context) async {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EncountersListPage()),
      );

      developer.log(
        'Navigated to encounters page',
        name: 'DeepLinkHandler',
      );

      return true;
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
      return false;
    }
  }

  /// Handle encounter detail deep link
  /// Format: devocional://encounter/{id} or devocional://encounter_detail/{id}
  Future<bool> _handleEncounterDetailDeepLink(
    BuildContext context,
    List<String> pathSegments,
  ) async {
    try {
      // Extract encounter ID from path segments
      // pathSegments[0] = 'encounter' or 'encounter_detail'
      // pathSegments[1] = encounter ID
      if (pathSegments.length < 2) {
        developer.log(
          'Missing encounter ID in path: ${pathSegments.join("/")}',
          name: 'DeepLinkHandler',
        );
        return false;
      }

      final encounterId = pathSegments[1];

      developer.log(
        'Deep link encounter ID: $encounterId',
        name: 'DeepLinkHandler',
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      // Navigate to encounters list first
      // In the future, could navigate directly to encounter detail
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EncountersListPage()),
      );

      developer.log(
        'Navigated to encounter: $encounterId',
        name: 'DeepLinkHandler',
      );

      return true;
    } catch (e) {
      developer.log(
        'Navigation error: $e',
        name: 'DeepLinkHandler',
        error: e,
      );
      return false;
    }
  }
}
