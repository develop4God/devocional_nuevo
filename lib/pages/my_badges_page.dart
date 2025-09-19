// lib/pages/my_badges_page.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyBadgesPage extends StatefulWidget {
  const MyBadgesPage({super.key});

  @override
  State<MyBadgesPage> createState() => _MyBadgesPageState();
}

class _MyBadgesPageState extends State<MyBadgesPage> {
  final DonationService _donationService = DonationService();

  List<String> _unlockedBadges = [];
  List<String> _allBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final unlockedBadges = await _donationService.getUnlockedBadges();
      final allBadges = await _donationService.getAvailableBadges();

      if (mounted) {
        setState(() {
          _unlockedBadges = unlockedBadges;
          _allBadges = allBadges;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBadgeDetails(String badgePath, bool isUnlocked) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _BadgeDetailDialog(
          badgePath: badgePath,
          isUnlocked: isUnlocked,
          onShare: () => _shareBadge(badgePath),
        );
      },
    );
  }

  void _shareBadge(String badgePath) {
    // TODO: Implement badge sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('donate.share_badge'.tr()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('donate.my_badges'.tr()),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBadgeGrid(colorScheme, textTheme),
    );
  }

  Widget _buildBadgeGrid(ColorScheme colorScheme, TextTheme textTheme) {
    if (_allBadges.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          _buildHeader(textTheme, colorScheme),

          const SizedBox(height: 24),

          // Badge grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _allBadges.length,
              itemBuilder: (context, index) {
                final badgePath = _allBadges[index];
                final isUnlocked = _unlockedBadges.contains(badgePath);

                return _buildBadgeItem(
                  badgePath,
                  isUnlocked,
                  colorScheme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    final progress = _allBadges.isNotEmpty
        ? _unlockedBadges.length / _allBadges.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'donate.badges_collection'.tr(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_unlockedBadges.length} of ${_allBadges.length} badges unlocked',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(
      String badgePath, bool isUnlocked, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _showBadgeDetails(badgePath, isUnlocked),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isUnlocked
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Stack(
            children: [
              _buildBadgeImage(badgePath, colorScheme, isUnlocked),

              // Lock overlay for locked badges
              if (!isUnlocked)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white.withOpacity(0.8),
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeImage(
      String badgePath, ColorScheme colorScheme, bool isUnlocked) {
    // For demonstration, create colored circles since we don't have actual images
    final colors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
    ];

    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.church,
      Icons.auto_awesome,
      Icons.local_fire_department,
    ];

    final index = _allBadges.indexOf(badgePath) % colors.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isUnlocked ? colors[index] : Colors.grey,
            isUnlocked
                ? colors[index].withOpacity(0.7)
                : Colors.grey.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icons[index],
          color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.military_tech_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'donate.no_badges'.tr(),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to donate page
                Navigator.pushNamed(context, '/donate');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.favorite),
              label: Text('donate.support_button'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeDetailDialog extends StatelessWidget {
  final String badgePath;
  final bool isUnlocked;
  final VoidCallback onShare;

  const _BadgeDetailDialog({
    required this.badgePath,
    required this.isUnlocked,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large badge preview
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? colorScheme.primary : colorScheme.outline,
                  width: 3,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    _buildBadgeImage(badgePath, colorScheme, isUnlocked),
                    if (!isUnlocked)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white.withOpacity(0.8),
                            size: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Badge name/title
            Text(
              isUnlocked ? 'Badge Unlocked!' : 'Badge Locked',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              isUnlocked
                  ? 'Thank you for your generous support!'
                  : 'Support our ministry to unlock this badge',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('app.close'.tr()),
                  ),
                ),
                if (isUnlocked) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onShare();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share, size: 16),
                      label: Text('donate.share_badge'.tr()),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeImage(
      String badgePath, ColorScheme colorScheme, bool isUnlocked) {
    // For demonstration, create colored circles since we don't have actual images
    final colors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
    ];

    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.church,
      Icons.auto_awesome,
      Icons.local_fire_department,
    ];

    final index = badgePath.hashCode % colors.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isUnlocked ? colors[index] : Colors.grey,
            isUnlocked
                ? colors[index].withOpacity(0.7)
                : Colors.grey.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icons[index],
          color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
          size: 48,
        ),
      ),
    );
  }
}
