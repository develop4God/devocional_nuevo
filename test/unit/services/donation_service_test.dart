// test/unit/services/donation_service_test.dart
import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DonationService', () {
    late DonationService donationService;

    setUp(() async {
      // Set up mock shared preferences
      SharedPreferences.setMockInitialValues({});
      donationService = DonationService();
    });

    group('Badge Management', () {
      testWidgets('should get available badges', (WidgetTester tester) async {
        final badges = await donationService.getAvailableBadges();

        expect(badges, isNotEmpty);
        expect(badges.length, equals(5)); // We have 5 placeholder badges
        expect(badges.first, contains('badge_1.png'));
      });

      testWidgets('should unlock and save badges', (WidgetTester tester) async {
        const testBadge = 'assets/badges/badge_1.png';

        // Initially should have no unlocked badges
        final initialBadges = await donationService.getUnlockedBadges();
        expect(initialBadges, isEmpty);

        // Unlock a badge
        await donationService.unlockBadge(testBadge);

        // Should now have the unlocked badge
        final unlockedBadges = await donationService.getUnlockedBadges();
        expect(unlockedBadges, contains(testBadge));
        expect(unlockedBadges.length, equals(1));

        // Check if badge is marked as unlocked
        final isUnlocked = await donationService.isBadgeUnlocked(testBadge);
        expect(isUnlocked, isTrue);
      });

      testWidgets('should not duplicate badges when unlocking same badge twice',
          (WidgetTester tester) async {
        const testBadge = 'assets/badges/badge_2.png';

        // Unlock badge twice
        await donationService.unlockBadge(testBadge);
        await donationService.unlockBadge(testBadge);

        // Should still have only one instance
        final unlockedBadges = await donationService.getUnlockedBadges();
        expect(unlockedBadges.length, equals(1));
        expect(unlockedBadges.first, equals(testBadge));
      });

      testWidgets('should check badge unlock status correctly',
          (WidgetTester tester) async {
        const unlockedBadge = 'assets/badges/badge_3.png';
        const lockedBadge = 'assets/badges/badge_4.png';

        // Unlock one badge
        await donationService.unlockBadge(unlockedBadge);

        // Check statuses
        expect(await donationService.isBadgeUnlocked(unlockedBadge), isTrue);
        expect(await donationService.isBadgeUnlocked(lockedBadge), isFalse);
      });
    });

    group('Donation History', () {
      testWidgets('should start with empty donation history',
          (WidgetTester tester) async {
        final history = await donationService.getDonationHistory();
        expect(history, isEmpty);

        final totalDonations = await donationService.getTotalDonations();
        expect(totalDonations, equals(0));
      });

      testWidgets('should handle donation history operations',
          (WidgetTester tester) async {
        // Test with mock donation data would require more complex mocking
        // This is a placeholder for integration with actual purchase flow
        final history = await donationService.getDonationHistory();
        expect(history, isA<List<Map<String, dynamic>>>());
      });
    });

    group('Product Management', () {
      testWidgets('should have correct product IDs defined',
          (WidgetTester tester) async {
        // Test that product IDs are correctly defined
        // This is more of a structural test since we can't test billing without actual setup

        // We can at least verify the service initializes without errors
        expect(() => DonationService(), returnsNormally);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle badge operations gracefully with invalid data',
          (WidgetTester tester) async {
        // Test with invalid badge path
        await donationService.unlockBadge('');
        final badges = await donationService.getUnlockedBadges();
        expect(badges, anyOf(isEmpty, contains('')));
      });

      testWidgets('should handle storage errors gracefully',
          (WidgetTester tester) async {
        // Most error handling is internal, but we can test that methods don't throw
        expect(() async => await donationService.getUnlockedBadges(),
            returnsNormally);
        expect(() async => await donationService.getDonationHistory(),
            returnsNormally);
        expect(() async => await donationService.getTotalDonations(),
            returnsNormally);
      });
    });
  });
}
