import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spiritual_stats_model.dart';
import '../extensions/string_extensions.dart';

/// Service for managing In-App Review requests
/// Shows review dialogs at optimal engagement moments (5th, 25th, 50th, 100th, 200th devotional)
/// Respects user preferences and cooldown periods
class InAppReviewService {
  // SharedPreferences keys
  static const String _userRatedAppKey = 'user_rated_app';
  static const String _neverAskReviewKey = 'never_ask_review_again';
  static const String _remindLaterDateKey = 'review_remind_later_date';
  static const String _reviewRequestCountKey = 'review_request_count';
  static const String _lastReviewRequestKey = 'last_review_request_date';
  static const String _firstTimeCheckKey = 'review_first_time_check_done';

  // Constants
  static const List<int> _milestones = [5, 25, 50, 100, 200];
  static const int _globalCooldownDays = 90;
  static const int _remindLaterDays = 30;

  /// Main entry point - checks if should show review and displays dialog
  static Future<void> checkAndShow(
      SpiritualStats stats, BuildContext context) async {
    try {
      debugPrint('🔍 InAppReview: Checking if should show review dialog');
      debugPrint('📊 Total devotionals read: ${stats.totalDevocionalesRead}');

      if (!context.mounted) {
        debugPrint('❌ InAppReview: Context not mounted, skipping');
        return;
      }

      final shouldShow =
      await shouldShowReviewRequest(stats.totalDevocionalesRead);

      if (shouldShow && context.mounted) {
        debugPrint('✅ InAppReview: Showing review dialog');
        await showReviewDialog(context);
      } else {
        debugPrint('⏭️ InAppReview: Conditions not met, skipping');
      }
    } catch (e) {
      debugPrint('❌ InAppReview Error: $e');
      // Fail silently - review failure should not affect devotional recording
    }
  }

  /// Determines if review request should be shown based on milestone and cooldown logic
  static Future<bool> shouldShowReviewRequest(int totalDevocionalesRead) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user already rated the app
      final userRated = prefs.getBool(_userRatedAppKey) ?? false;
      if (userRated) {
        debugPrint('🚫 InAppReview: User already rated app');
        return false;
      }

      // Check if user chose "never ask again"
      final neverAsk = prefs.getBool(_neverAskReviewKey) ?? false;
      if (neverAsk) {
        debugPrint('🚫 InAppReview: User chose never ask again');
        return false;
      }

      // Check for first-time users with existing devotionals (5+)
      final firstTimeCheckDone = prefs.getBool(_firstTimeCheckKey) ?? false;
      if (!firstTimeCheckDone && totalDevocionalesRead >= 5) {
        debugPrint(
            '🆕 InAppReview: First time check - user has $totalDevocionalesRead devotionals');

        // Mark first time check as done
        await prefs.setBool(_firstTimeCheckKey, true);

        // Check cooldown periods before showing
        if (await _checkCooldownPeriods(prefs)) {
          debugPrint(
              '✅ InAppReview: First time user with 5+ devotionals, showing review');
          return true;
        }
      }

      // Check if we've reached a milestone
      final isMilestone = _milestones.contains(totalDevocionalesRead);
      if (!isMilestone) {
        debugPrint('⏭️ InAppReview: Not a milestone ($totalDevocionalesRead)');
        return false;
      }

      debugPrint('🎯 InAppReview: Milestone reached! ($totalDevocionalesRead)');

      // Check cooldown periods
      if (await _checkCooldownPeriods(prefs)) {
        debugPrint('✅ InAppReview: All conditions met, should show review');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ InAppReview shouldShow error: $e');
      return false;
    }
  }

  /// Helper method to check cooldown periods
  static Future<bool> _checkCooldownPeriods(SharedPreferences prefs) async {
    // Check global cooldown (90+ days since last request)
    final lastRequestTimestamp = prefs.getInt(_lastReviewRequestKey) ?? 0;
    if (lastRequestTimestamp > 0) {
      final lastRequestDate =
      DateTime.fromMillisecondsSinceEpoch(lastRequestTimestamp * 1000);
      final daysSinceLastRequest =
          DateTime.now().difference(lastRequestDate).inDays;

      if (daysSinceLastRequest < _globalCooldownDays) {
        debugPrint(
            'Global cooldown active ($daysSinceLastRequest/$_globalCooldownDays days)');
        return false;
      }
    }

    // Check "remind later" cooldown (30+ days)
    final remindLaterTimestamp = prefs.getInt(_remindLaterDateKey) ?? 0;
    if (remindLaterTimestamp > 0) {
      final remindLaterDate =
      DateTime.fromMillisecondsSinceEpoch(remindLaterTimestamp * 1000);
      final daysSinceRemindLater =
          DateTime.now().difference(remindLaterDate).inDays;

      if (daysSinceRemindLater < _remindLaterDays) {
        debugPrint(
            'Remind later cooldown active ($daysSinceRemindLater/$_remindLaterDays days)');
        return false;
      }
    }

    return true;
  }

  /// Shows the custom review dialog with three options
  static Future<void> showReviewDialog(BuildContext context) async {
    if (!context.mounted) return;

    try {
      // Record that we attempted to show review
      await _recordReviewAttempt();

      // Check context is still mounted before using it
      if (!context.mounted) return;

      // Get theme colors
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      // Check context again before showing dialog
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: Text(
              'review.title'.tr(),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'review.message'.tr(),
              style: TextStyle(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            actions: [
              // "Share" button - primary action
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _markUserAsRated();
                  if (context.mounted) {
                    await requestInAppReview(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text('review.button_share'.tr()),
              ),

              // "Already rated" button
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _markUserAsRated();
                },
                child: Text(
                  'review.button_already_rated'.tr(),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),

              // "Not now" button - sets remind later
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _setRemindLater();
                },
                child: Text(
                  'review.button_not_now'.tr(),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('❌ InAppReview dialog error: $e');
    }
  }

  /// Attempts to request in-app review, with Play Store fallback
  static Future<void> requestInAppReview(BuildContext context) async {
    try {
      final InAppReview inAppReview = InAppReview.instance;

      // In debug mode, always use fallback for reliable testing
      if (kDebugMode) {
        debugPrint('🐛 InAppReview: Debug mode - using Play Store fallback');
        if (context.mounted) {
          await _showPlayStoreFallback(context);
        }
        return;
      }

      if (await inAppReview.isAvailable()) {
        debugPrint('📱 InAppReview: Requesting native in-app review');
        await inAppReview.requestReview();

        // Add a small delay to check if native review appeared
        await Future.delayed(const Duration(milliseconds: 500));

        // Note: We can't reliably detect if the native review actually appeared,
        // but we provide fallback option in case user dismisses quickly
        debugPrint('📱 InAppReview: Native review request completed');
      } else {
        debugPrint(
            '🌐 InAppReview: Native not available, showing fallback dialog');
        if (context.mounted) {
          await _showPlayStoreFallback(context);
        }
      }
    } catch (e) {
      debugPrint('❌ InAppReview request error: $e');
      if (context.mounted) {
        await _showPlayStoreFallback(context);
      }
    }
  }

  /// Shows fallback dialog to go to Play Store
  static Future<void> _showPlayStoreFallback(BuildContext context) async {
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'review.fallback_title'.tr(),
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Text(
            'review.fallback_message'.tr(),
            style: TextStyle(color: colorScheme.onSurface),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: Text('review.fallback_go'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'review.fallback_cancel'.tr(),
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _openPlayStore();
    }
  }

  /// Opens Play Store for the app
  static Future<void> _openPlayStore() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      await inAppReview.openStoreListing(
        appStoreId:
        'com.develop4god.devocional_nuevo', // Replace with actual app ID
      );
      debugPrint('🏪 InAppReview: Opened Play Store');
    } catch (e) {
      debugPrint('❌ InAppReview Play Store error: $e');
      // Try direct URL as fallback
      try {
        final url = Uri.parse(
            'https://play.google.com/store/apps/details?id=com.develop4god.devocional_nuevo');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (urlError) {
        debugPrint('❌ InAppReview URL fallback error: $urlError');
      }
    }
  }

  /// Records that we attempted to show a review request
  static Future<void> _recordReviewAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update request count
      final currentCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
      await prefs.setInt(_reviewRequestCountKey, currentCount + 1);

      // Update last request date
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(_lastReviewRequestKey, now);

      debugPrint('Recorded attempt #${currentCount + 1}');
    } catch (e) {
      debugPrint('❌ InAppReview record attempt error: $e');
    }
  }

  /// Marks user as having rated the app (permanently)
  static Future<void> _markUserAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userRatedAppKey, true);
      debugPrint('✅ InAppReview: User marked as rated');
    } catch (e) {
      debugPrint('❌ InAppReview mark rated error: $e');
    }
  }

  /// Sets remind later timestamp (30 days cooldown)
  static Future<void> _setRemindLater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(_remindLaterDateKey, now);
      debugPrint('⏰ InAppReview: Remind later set for 30 days');
    } catch (e) {
      debugPrint('❌ InAppReview remind later error: $e');
    }
  }

  /// Clears all review preferences (for testing/debugging)
  static Future<void> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRatedAppKey);
      await prefs.remove(_neverAskReviewKey);
      await prefs.remove(_remindLaterDateKey);
      await prefs.remove(_reviewRequestCountKey);
      await prefs.remove(_lastReviewRequestKey);
      await prefs.remove(_firstTimeCheckKey);
      debugPrint('🧹 InAppReview: All preferences cleared');
    } catch (e) {
      debugPrint('❌ InAppReview clear error: $e');
    }
  }
}