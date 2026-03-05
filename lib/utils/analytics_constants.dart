/// Campaign tag constants for Firebase Analytics audience segmentation
///
/// This class provides centralized constants and methods for analytics campaign
/// tags used in Firebase Analytics events. This enables the marketing team to
/// create custom audiences for targeted In-App Messaging campaigns.
class AnalyticsConstants {
  // Private constructor to prevent instantiation
  AnalyticsConstants._();

  /// Default campaign tag for devotional completion events
  /// Used for: Donation campaign audience targeting
  ///
  /// Marketing team can create audience with:
  /// - Event: `devotional_read_complete`
  /// - Where `campaign_tag` = `'custom_1'`
  static const String defaultCampaignTag = 'custom_1';

  /// Returns campaign tag for a given devotional
  ///
  /// Currently returns [defaultCampaignTag] for all devotionals.
  /// This method is extensible for future per-devotional logic based on:
  /// - Devotional ID
  /// - Categories
  /// - User segments
  /// - A/B testing groups
  ///
  /// Example future implementation:
  /// ```dart
  /// static String getCampaignTag({String? devocionalId}) {
  ///   if (devocionalId?.startsWith('special_') ?? false) {
  ///     return 'custom_2'; // Different campaign for special devotionals
  ///   }
  ///   return defaultCampaignTag;
  /// }
  /// ```
  static String getCampaignTag({
    String? devocionalId,
    int? totalDevocionalesRead,
  }) {
    // Solo retorna 'custom_1' si el usuario ha completado 7 o más devocionales
    if (totalDevocionalesRead != null && totalDevocionalesRead >= 7) {
      return defaultCampaignTag;
    }
    return '';
  }
}
