// lib/pages/progress_page.dart - Fixed themed shadows
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/spiritual_stats_model.dart';
import '../pages/favorites_page.dart';
import '../providers/devocional_provider.dart';
import '../services/spiritual_stats_service.dart';

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
    _showAchievementTipIfNeeded();
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
      final devocionalProvider =
          Provider.of<DevocionalProvider>(context, listen: false);
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

  // 💡 MOSTRAR TIP EDUCATIVO SOBRE LOGROS (SOLO 2 VECES)
  Future<void> _showAchievementTipIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tipShownCount = prefs.getInt('achievement_tip_count') ?? 0;

      // Solo mostrar si se ha mostrado menos de 2 veces
      if (tipShownCount < 2) {
        // Esperar un poco para que la pantalla cargue completamente
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          _showEducationalSnackBar();

          // Incrementar contador
          await prefs.setInt('achievement_tip_count', tipShownCount + 1);
        }
      }
    } catch (e) {
      // Si hay error con SharedPreferences, no mostrar el tip
      debugPrint('Error showing achievement tip: $e');
    }
  }

  void _showEducationalSnackBar() {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Consejo útil',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toca cualquier logro para ver información completa',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 8),
        elevation: 6,
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _streakAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.14159),
            // Esto invierte horizontalmente el icono
            child: const Icon(Icons.exit_to_app),
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Regresar',
        ),
        title: Text(
          'Mi Progreso Espiritual',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        // Si quieres centrar igual que otras páginas
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
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
          const SizedBox(height: 18),
          _buildStatsCards(),
          const SizedBox(height: 1),
          _buildAchievementsSection(),
          const SizedBox(height: 18), // Extra bottom padding
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
            // ✨ AQUÍ APLICAMOS COLOR DEL TEMA A LA SOMBRA
            shadowColor: colorScheme.primary.withValues(alpha: 1),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
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
                      fontSize: 30, //tamaño de caha de racha actual
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    _stats!.currentStreak == 1 ? 'día' : 'días',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withValues(alpha: 0.3),
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
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
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
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(); // Regresa a la página anterior
            },
            borderRadius: BorderRadius.circular(16),
            child: _buildStatCard(
              title: 'Devocionales completos',
              value: '${_stats!.totalDevocionalesRead}',
              icon: Icons.auto_stories,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: _buildStatCard(
              title: 'Favoritos guardados',
              value: '${_stats!.favoritesCount}',
              icon: Icons.favorite,
              color: Colors.pink,
            ),
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
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // ✨ SOMBRA TEMÁTICA
      shadowColor: colorScheme.primary.withValues(alpha: 1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1.3),
                duration: const Duration(milliseconds: 800),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Logros',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 6,
          ),
          itemCount: allAchievements.length,
          itemBuilder: (context, index) {
            final achievement = allAchievements[index];
            final isUnlocked = unlockedIds.contains(achievement.id);
            return _buildAchievementCard(achievement, isUnlocked);
          },
        ),
        const SizedBox(height: 12),
        // Última actividad cerca del grid
        Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 1),
            Text(
              'Última Actividad: ${_stats!.lastActivityDate != null ? DateFormat('dd/MM/yyyy').format(_stats!.lastActivityDate!) : 'Sin actividad'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 🎯 TOOLTIP CON TAP SIMPLE + AUTO-CIERRE
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: Duration(seconds: 2),
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: isUnlocked ? achievement.color : Colors.grey,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      preferBelow: false,
      verticalOffset: 10,
      child: Card(
        elevation: isUnlocked ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // ✨ SOMBRA TEMÁTICA DIFERENCIADA
        shadowColor: isUnlocked
            ? achievement.color.withValues(alpha: 1)
            : colorScheme.outline.withValues(alpha: 1),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: isUnlocked
                      ? achievement.color.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  radius: 14,
                  child: Icon(
                    achievement.icon,
                    color: isUnlocked ? achievement.color : Colors.grey,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          achievement.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Flexible(
                        child: Text(
                          achievement.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 8,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
