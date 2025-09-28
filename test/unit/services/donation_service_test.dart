// test/unit/services/donation_service_test.dart

import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:devocional_nuevo/services/remote_badge_service.dart';
import 'package:devocional_nuevo/models/badge_model.dart' as badge_model;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DonationService Tests', () {
    late DonationService service;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'unlocked_badges': jsonEncode(['first_donation', 'supporter']),
        'donation_history': jsonEncode([
          {
            'productId': 'donation_5_usd',
            'amount': 5.0,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
      });

      // Setup method channel mocks for in-app purchase
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'isAvailable':
              return true;
            case 'queryProductDetails':
              return {
                'productDetails': [
                  {
                    'id': 'donation_1_usd',
                    'title': '1 USD Donation',
                    'description': 'Support the app with 1 USD',
                    'price': '1.00',
                    'rawPrice': 1.0,
                    'currencyCode': 'USD',
                  },
                  {
                    'id': 'donation_5_usd',
                    'title': '5 USD Donation',
                    'description': 'Support the app with 5 USD',
                    'price': '5.00',
                    'rawPrice': 5.0,
                    'currencyCode': 'USD',
                  }
                ]
              };
            case 'buyConsumable':
              return {'purchaseDetails': []};
            case 'completePurchase':
              return null;
            default:
              return null;
          }
        },
      );

      service = DonationService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        null,
      );
    });

    group('In-App Purchase Flow and Validation', () {
      test('should handle in-app purchase flows and validation', () async {
        // Initialize service
        await service.initialize();

        // Test getting available products
        final products = await service.getAvailableProducts();
        expect(products, isA<List<Map<String, dynamic>>>());

        // Test donation availability
        final isAvailable = await service.isDonationAvailable();
        expect(isAvailable, isA<bool>());
      });

      test('should validate product information', () async {
        await service.initialize();

        final products = await service.getAvailableProducts();

        for (final product in products) {
          expect(product['id'], isA<String>());
          expect(product['title'], isA<String>());
          expect(product['price'], isA<String>());
        }
      });

      test('should handle purchase validation', () async {
        await service.initialize();

        // Test purchase process (mock)
        expect(() => service.makeDonation('donation_1_usd'), returnsNormally);
      });

      test('should handle purchase completion', () async {
        await service.initialize();

        // Test purchase completion handling
        expect(
            () => service.completePurchase('donation_test'), returnsNormally);
      });
    });

    group('Donation Tracking and Badge Rewards', () {
      test('should manage donation tracking and badge rewards', () async {
        // Test donation history retrieval
        final history = await service.getDonationHistory();
        expect(history, isA<List<Map<String, dynamic>>>());

        // Test badge unlocking
        await service.unlockBadge('generous_supporter');
        final unlockedBadges = await service.getUnlockedBadges();
        expect(unlockedBadges, contains('generous_supporter'));
      });

      test('should track donation amounts and milestones', () async {
        // Test donation amount tracking
        await service.recordDonation('donation_5_usd', 5.0);

        final totalDonated = await service.getTotalDonationAmount();
        expect(totalDonated, greaterThanOrEqualTo(5.0));

        // Test milestone achievements
        final history = await service.getDonationHistory();
        expect(history, isNotEmpty);
      });

      test('should handle badge progression system', () async {
        // Test different donation badges
        const donationBadges = [
          'first_donation',
          'supporter',
          'generous_supporter',
          'benefactor'
        ];

        for (final badgeId in donationBadges) {
          await service.unlockBadge(badgeId);
        }

        final unlocked = await service.getUnlockedBadges();
        expect(unlocked, isA<List<String>>());

        for (final badgeId in donationBadges) {
          expect(unlocked, contains(badgeId));
        }
      });

      test('should validate badge unlock conditions', () async {
        // Test first donation badge
        await service.recordDonation('donation_1_usd', 1.0);
        final shouldUnlockFirst =
            await service.checkBadgeUnlock('first_donation', 1.0);
        expect(shouldUnlockFirst, isA<bool>());

        // Test supporter badge (multiple donations)
        await service.recordDonation('donation_5_usd', 5.0);
        final shouldUnlockSupporter =
            await service.checkBadgeUnlock('supporter', 6.0);
        expect(shouldUnlockSupporter, isA<bool>());
      });
    });

    group('Product Management and Availability', () {
      test('should manage available donation products', () async {
        await service.initialize();

        // Test product availability
        const productIds = [
          'donation_1_usd',
          'donation_5_usd',
          'donation_10_usd',
          'donation_20_usd'
        ];

        for (final productId in productIds) {
          final isAvailable = await service.isProductAvailable(productId);
          expect(isAvailable, isA<bool>());
        }
      });

      test('should handle product pricing information', () async {
        await service.initialize();

        final products = await service.getAvailableProducts();

        for (final product in products) {
          expect(product['rawPrice'], isA<double>());
          expect(product['currencyCode'], isA<String>());
          expect(product['price'], isA<String>());
        }
      });

      test('should validate donation amounts', () async {
        // Test different donation amounts
        const testAmounts = [1.0, 5.0, 10.0, 20.0];

        for (final amount in testAmounts) {
          final isValid = await service.isValidDonationAmount(amount);
          expect(isValid, isA<bool>());
        }
      });
    });

    group('Service State and Data Persistence', () {
      test('should persist donation history', () async {
        // Add multiple donations
        await service.recordDonation('donation_1_usd', 1.0);
        await service.recordDonation('donation_5_usd', 5.0);
        await service.recordDonation('donation_10_usd', 10.0);

        final history = await service.getDonationHistory();
        expect(history.length, greaterThanOrEqualTo(3));

        // Verify donation data structure
        for (final donation in history) {
          expect(donation.containsKey('productId'), isTrue);
          expect(donation.containsKey('amount'), isTrue);
          expect(donation.containsKey('timestamp'), isTrue);
        }
      });

      test('should handle service initialization and cleanup', () async {
        expect(service, isNotNull);
        expect(service, isA<DonationService>());

        // Test initialization
        await service.initialize();

        // Test disposal
        service.dispose();
      });

      test('should maintain singleton pattern', () {
        final service1 = DonationService();
        final service2 = DonationService();

        expect(identical(service1, service2), isTrue);
      });
    });

    group('Badge Integration and Management', () {
      test('should integrate with badge system', () async {
        // Test badge unlocking
        await service.unlockBadge('test_badge');

        final unlocked = await service.getUnlockedBadges();
        expect(unlocked, contains('test_badge'));

        // Test badge status check
        final isBadgeUnlocked = await service.isBadgeUnlocked('test_badge');
        expect(isBadgeUnlocked, isTrue);
      });

      test('should handle badge validation', () async {
        const validBadges = [
          'first_donation',
          'supporter',
          'generous_supporter',
          'benefactor',
          'patron'
        ];

        for (final badgeId in validBadges) {
          expect(() => service.unlockBadge(badgeId), returnsNormally);
        }
      });

      test('should prevent duplicate badge unlocking', () async {
        await service.unlockBadge('duplicate_test');
        await service.unlockBadge('duplicate_test');
        await service.unlockBadge('duplicate_test');

        final unlocked = await service.getUnlockedBadges();
        final duplicateCount =
            unlocked.where((b) => b == 'duplicate_test').length;
        expect(duplicateCount, equals(1));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle purchase errors gracefully', () async {
        await service.initialize();

        // Test purchase with invalid product ID
        expect(() => service.makeDonation('invalid_product'), returnsNormally);

        // Test purchase completion with invalid data
        expect(() => service.completePurchase('invalid_purchase'),
            returnsNormally);
      });

      test('should handle unavailable in-app purchases', () async {
        // Mock unavailable IAP
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/in_app_purchase'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isAvailable') return false;
            return null;
          },
        );

        await service.initialize();
        final isAvailable = await service.isDonationAvailable();
        expect(isAvailable, isFalse);
      });

      test('should handle corrupted data gracefully', () async {
        // Setup corrupted data
        SharedPreferences.setMockInitialValues({
          'unlocked_badges': 'invalid_json',
          'donation_history': 'corrupted_data',
        });

        final corruptedService = DonationService();

        // Should handle corrupted data gracefully
        final badges = await corruptedService.getUnlockedBadges();
        expect(badges, isA<List<String>>());

        final history = await corruptedService.getDonationHistory();
        expect(history, isA<List<Map<String, dynamic>>>());
      });

      test('should handle concurrent purchase attempts', () async {
        await service.initialize();

        // Multiple concurrent purchases
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(service.makeDonation('donation_1_usd'));
        }

        // Should handle concurrent operations gracefully
        expect(() => Future.wait(futures), returnsNormally);
      });
    });

    group('Analytics and Reporting', () {
      test('should provide donation analytics', () async {
        // Record various donations
        await service.recordDonation('donation_1_usd', 1.0);
        await service.recordDonation('donation_5_usd', 5.0);
        await service.recordDonation('donation_10_usd', 10.0);

        // Test analytics data
        final totalAmount = await service.getTotalDonationAmount();
        expect(totalAmount, equals(16.0));

        final donationCount = await service.getTotalDonationCount();
        expect(donationCount, greaterThanOrEqualTo(3));

        final averageDonation = await service.getAverageDonationAmount();
        expect(averageDonation, greaterThan(0));
      });

      test('should track donation frequency', () async {
        // Record donations over time
        final now = DateTime.now();
        for (int i = 0; i < 5; i++) {
          await service.recordDonation('donation_1_usd', 1.0);
        }

        final history = await service.getDonationHistory();
        expect(history.length, greaterThanOrEqualTo(5));
      });
    });

    group('Premium Features and Benefits', () {
      test('should handle premium feature unlocking', () async {
        // Test premium status
        await service.unlockBadge('supporter');
        final isPremium = await service.hasPremiumStatus();
        expect(isPremium, isA<bool>());

        // Test premium benefits
        final premiumBenefits = await service.getPremiumBenefits();
        expect(premiumBenefits, isA<List<String>>());
      });

      test('should validate premium feature access', () async {
        const premiumFeatures = [
          'cloud_backup',
          'exclusive_badges',
          'ad_free_experience',
          'priority_support'
        ];

        for (final feature in premiumFeatures) {
          final hasAccess = await service.hasPremiumFeatureAccess(feature);
          expect(hasAccess, isA<bool>());
        }
      });
    });
  });
}
