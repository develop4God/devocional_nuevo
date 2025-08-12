// lib/pages/progress_page.dart - Fixed overflow issues

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/spiritual_stats_model.dart';
import '../services/spiritual_stats_service.dart';
import '../providers/devocional_provider.dart';
import '../pages/favorites_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with TickerProviderStateMixin {
  final SpiritualStatsService _statsService = SpiritualStatsService();
  SpiritualStats? _stats;
  bool _isLoading = true;
  late AnimationController _streakAnimationController;
  late Animation<double> _streakAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStats();
  }

  void _initAnimations() {
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _streakAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _streakAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devocionalProvider = Provider.of<DevocionalProvider>(context, listen: false);
      final favoritesCount = devocionalProvider.favoriteDevocionales.length;
      
      final stats = await _statsService.updateFavoritesCount(favoritesCount);
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
      
      _streakAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _streakAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso Espiritual'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar las estadísticas',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStats,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakCard(),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildAchievementsSection(),
          const SizedBox(height: 20),
          _buildQuickActionsSection(),
          const SizedBox(height: 20), // Extra bottom padding
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _streakAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _streakAnimation.value),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 28, // Slightly smaller
                      ),
                      const SizedBox(width: 8),
                      Flexible( // Allow text to wrap if needed
                        child: Text(
                          'Racha Actual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_stats!.currentStreak}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    _stats!.currentStreak == 1 ? 'día' : 'días',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStreakProgress(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakProgress() {
    final currentStreak = _stats!.currentStreak;
    final nextMilestone = _getNextStreakMilestone(currentStreak);
    final progress = nextMilestone > 0 ? currentStreak / nextMilestone : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          nextMilestone > 0
              ? 'Siguiente meta: $nextMilestone días'
              : '¡Meta alcanzada!',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  int _getNextStreakMilestone(int currentStreak) {
    final milestones = [3, 7, 14, 21, 30, 50, 100];
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone;
      }
    }
    return 0; // No more milestones
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Devocionales',
            value: '${_stats!.totalDevocionalesRead}',
            icon: Icons.auto_stories,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Favoritos',
            value: '${_stats!.favoritesCount}',
            icon: Icons.favorite,
            color: Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16 to 12
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 20, // Reduced from 24 to 20
              child: Icon(
                icon,
                color: color,
                size: 20, // Reduced from 24 to 20
              ),
            ),
            const SizedBox(height: 8), // Reduced from 12 to 8
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 20, // Explicit size to ensure consistency
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12, // Explicit size
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final allAchievements = PredefinedAchievements.all;
    final unlockedIds = _stats!.unlockedAchievements.map((a) => a.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
      children: [
        Text(
          'Logros',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8, // Increased from 2.5 to give more height
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: allAchievements.length,
          itemBuilder: (context, index) {
            final achievement = allAchievements[index];
            final isUnlocked = unlockedIds.contains(achievement.id);
            return _buildAchievementCard(achievement, isUnlocked);
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isUnlocked ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(10), // Reduced from 12 to 10
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: isUnlocked
                    ? achievement.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                radius: 16, // Reduced from 20 to 16
                child: Icon(
                  achievement.icon,
                  color: isUnlocked ? achievement.color : Colors.grey,
                  size: 16, // Reduced from 20 to 16
                ),
              ),
              const SizedBox(width: 10), // Reduced from 12 to 10
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Prevent expansion
                  children: [
                    Text(
                      achievement.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11, // Reduced from 12 to 11
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9, // Reduced from 10 to 9
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
      children: [
        Text(
          'Acciones Rápidas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Ver Favoritos',
                icon: Icons.bookmark,
                color: Colors.indigo,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Última Actividad',
                icon: Icons.schedule,
                color: Colors.green,
                subtitle: _stats!.lastActivityDate != null
                    ? DateFormat('dd/MM/yyyy').format(_stats!.lastActivityDate!)
                    : 'Sin actividad',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced from 16 to 12
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 20, // Reduced from 24 to 20
                child: Icon(
                  icon,
                  color: color,
                  size: 20, // Reduced from 24 to 20
                ),
              ),
              const SizedBox(height: 8), // Reduced from 12 to 8
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Explicit size
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 10, // Explicit size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}