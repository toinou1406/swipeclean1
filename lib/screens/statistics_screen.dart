import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Statistiques',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: () => _showResetDialog(context, appProvider),
                icon: Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSessionStats(context, appProvider),
                const SizedBox(height: 24),
                _buildDailyStats(context, appProvider),
                const SizedBox(height: 24),
                _buildOverallStats(context, appProvider),
                const SizedBox(height: 24),
                _buildEfficiencyStats(context, appProvider),
                const SizedBox(height: 24),
                _buildWeeklyTrend(context, appProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionStats(BuildContext context, AppProvider appProvider) {
    final sessionDuration = appProvider.sessionDuration;
    final photosProcessed = appProvider.sessionPhotosProcessed;
    final efficiency = appProvider.efficiency;

    return _StatsSection(
      title: 'Session actuelle',
      icon: Icons.timer,
      color: AppConstants.primaryColor,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Durée',
                value: '${sessionDuration.inMinutes}min',
                subtitle: '${sessionDuration.inSeconds % 60}s',
                icon: Icons.access_time,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Photos traitées',
                value: photosProcessed.toString(),
                subtitle: 'cette session',
                icon: Icons.photo,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Vitesse de traitement',
          value: '${efficiency['sessionRate'].toStringAsFixed(1)}',
          subtitle: 'photos par minute',
          icon: Icons.speed,
          color: AppConstants.primaryColor,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildDailyStats(BuildContext context, AppProvider appProvider) {
    final dailyStats = appProvider.dailyStatistics;
    final totalToday = appProvider.totalActionsToday;

    return _StatsSection(
      title: 'Aujourd\'hui',
      icon: Icons.today,
      color: AppConstants.swipeRightColor,
      children: [
        _StatCard(
          title: 'Actions totales',
          value: totalToday.toString(),
          subtitle: 'aujourd\'hui',
          icon: Icons.touch_app,
          color: AppConstants.swipeRightColor,
          isWide: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Conservées',
                value: (dailyStats['kept'] ?? 0).toString(),
                icon: Icons.check,
                color: AppConstants.swipeRightColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Supprimées',
                value: (dailyStats['deleted'] ?? 0).toString(),
                icon: Icons.delete,
                color: AppConstants.swipeLeftColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Déplacées',
                value: (dailyStats['moved'] ?? 0).toString(),
                icon: Icons.folder,
                color: AppConstants.swipeUpColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallStats(BuildContext context, AppProvider appProvider) {
    final stats = appProvider.statistics;

    return _StatsSection(
      title: 'Statistiques globales',
      icon: Icons.analytics,
      color: AppConstants.secondaryColor,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total actions',
                value: (stats['totalActions'] ?? 0).toString(),
                icon: Icons.gesture,
                color: AppConstants.secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Photos conservées',
                value: (stats['totalKept'] ?? 0).toString(),
                icon: Icons.favorite,
                color: AppConstants.swipeRightColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Photos supprimées',
                value: (stats['totalDeleted'] ?? 0).toString(),
                icon: Icons.delete_forever,
                color: AppConstants.swipeLeftColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Actions annulées',
                value: (stats['totalUndone'] ?? 0).toString(),
                icon: Icons.undo,
                color: AppConstants.swipeDownColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEfficiencyStats(BuildContext context, AppProvider appProvider) {
    final efficiency = appProvider.efficiency;
    final accuracy = (efficiency['accuracy'] * 100).round();
    final overallRate = efficiency['overallRate'].toStringAsFixed(2);

    return _StatsSection(
      title: 'Efficacité',
      icon: Icons.trending_up,
      color: AppConstants.swipeUpColor,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Précision',
                value: '$accuracy%',
                subtitle: 'actions réussies',
                icon: Icons.target,
                color: AppConstants.swipeUpColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Vitesse moyenne',
                value: overallRate,
                subtitle: 'photos/min',
                icon: Icons.speed,
                color: AppConstants.swipeUpColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyTrend(BuildContext context, AppProvider appProvider) {
    final weeklyTrend = appProvider.weeklyTrend;

    return _StatsSection(
      title: 'Tendance hebdomadaire',
      icon: Icons.show_chart,
      color: AppConstants.swipeDownColor,
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weeklyTrend.map((day) {
                    final total = day['total'] as int;
                    final maxValue = weeklyTrend
                        .map((d) => d['total'] as int)
                        .reduce((a, b) => a > b ? a : b);
                    final height = maxValue > 0 ? (total / maxValue) * 120 : 0.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          total.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: height,
                          decoration: BoxDecoration(
                            color: AppConstants.swipeDownColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day['dayName'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Réinitialiser les statistiques',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir réinitialiser toutes les statistiques ? Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await appProvider.statisticsService.resetStatistics();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Statistiques réinitialisées'),
                  backgroundColor: AppConstants.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.swipeLeftColor,
            ),
            child: Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _StatsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isWide
          ? Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            value,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const Spacer(),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
    );
  }
}