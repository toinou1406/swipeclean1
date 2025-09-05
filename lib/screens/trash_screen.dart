import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../models/trash_item.dart';
import '../services/trash_service.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Corbeille',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            actions: [
              if (appProvider.trashItems.isNotEmpty)
                IconButton(
                  onPressed: () => _showEmptyTrashDialog(context, appProvider),
                  icon: Icon(Icons.delete_forever, color: AppConstants.swipeLeftColor),
                ),
            ],
          ),
          body: StreamBuilder<List<TrashItem>>(
            stream: TrashService.instance.trashStream,
            builder: (context, snapshot) {
              final trashItems = snapshot.data ?? appProvider.trashItems;
              
              if (trashItems.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  _buildHeader(context, trashItems),
                  Expanded(
                    child: _buildTrashList(context, appProvider, trashItems),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 80,
              color: Colors.white38,
            ),
            const SizedBox(height: 24),
            Text(
              'Corbeille vide',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Les photos supprimées apparaîtront ici et seront automatiquement supprimées après 10 minutes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<TrashItem> trashItems) {
    final stats = TrashService.instance.getStatistics();
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.swipeLeftColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.swipeLeftColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Les photos seront définitivement supprimées après 10 minutes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'Photos',
                value: stats['itemCount'].toString(),
                icon: Icons.photo,
              ),
              _StatItem(
                label: 'Taille',
                value: '${stats['totalSizeMB']} MB',
                icon: Icons.storage,
              ),
              _StatItem(
                label: 'Expire bientôt',
                value: stats['itemsExpiringSoon'].toString(),
                icon: Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrashList(BuildContext context, AppProvider appProvider, List<TrashItem> trashItems) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: trashItems.length,
      itemBuilder: (context, index) {
        final item = trashItems[index];
        return _TrashItemCard(
          item: item,
          onRestore: () => _restoreItem(context, appProvider, item),
          onDelete: () => _deleteItem(context, appProvider, item),
        );
      },
    );
  }

  void _restoreItem(BuildContext context, AppProvider appProvider, TrashItem item) async {
    final success = await TrashService.instance.restoreFromTrash(item.photo.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.photo.name} restaurée'),
          backgroundColor: AppConstants.swipeRightColor,
        ),
      );
      appProvider.refreshTrash();
    }
  }

  void _deleteItem(BuildContext context, AppProvider appProvider, TrashItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Supprimer définitivement',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement "${item.photo.name}" ? Cette action est irréversible.',
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
              await TrashService.instance.permanentlyDelete(item.photo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.photo.name} supprimée définitivement'),
                  backgroundColor: AppConstants.swipeLeftColor,
                ),
              );
              appProvider.refreshTrash();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.swipeLeftColor,
            ),
            child: Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmptyTrashDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Vider la corbeille',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vider complètement la corbeille ? Toutes les photos seront définitivement supprimées.',
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
              await TrashService.instance.emptyTrash();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Corbeille vidée'),
                  backgroundColor: AppConstants.swipeLeftColor,
                ),
              );
              appProvider.refreshTrash();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.swipeLeftColor,
            ),
            child: Text(
              'Vider',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.swipeLeftColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _TrashItemCard extends StatefulWidget {
  final TrashItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItemCard({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  State<_TrashItemCard> createState() => _TrashItemCardState();
}

class _TrashItemCardState extends State<_TrashItemCard>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: widget.item.timeRemaining,
      vsync: this,
    );
    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_timerController);
    
    if (!widget.item.isExpired) {
      _timerController.forward();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = widget.item.timeRemaining.inMinutes < 2;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpiringSoon 
                  ? AppConstants.swipeLeftColor.withOpacity(0.5)
                  : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Photo thumbnail placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image,
                      color: Colors.white38,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.photo.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.item.photo.size / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: isExpiringSoon 
                                  ? AppConstants.swipeLeftColor 
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.timeRemainingFormatted,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isExpiringSoon 
                                    ? AppConstants.swipeLeftColor 
                                    : Colors.white70,
                                fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: widget.item.canRestore ? widget.onRestore : null,
                        icon: Icon(
                          Icons.restore,
                          color: widget.item.canRestore 
                              ? AppConstants.swipeRightColor 
                              : Colors.white38,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(
                          Icons.delete_forever,
                          color: AppConstants.swipeLeftColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _timerAnimation.value,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isExpiringSoon 
                          ? AppConstants.swipeLeftColor 
                          : AppConstants.swipeDownColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}