import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../models/swipe_action.dart';
import '../models/photo.dart';
import '../models/album.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _overlayController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _overlayAnimation;

  Offset _dragOffset = Offset.zero;
  SwipeDirection? _currentDirection;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      duration: AppConstants.swipeAnimationDuration,
      vsync: this,
    );
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _swipeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swipeController, curve: AppConstants.swipeAnimationCurve),
    );
    _overlayAnimation = Tween<double>(begin: 0, end: 1).animate(_overlayController);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final currentAlbum = appProvider.currentAlbum;
        if (currentAlbum == null || currentAlbum.photos.isEmpty) {
          return _buildEmptyState(context, appProvider);
        }

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, appProvider, currentAlbum),
                Expanded(
                  child: _buildSwipeArea(context, appProvider, currentAlbum),
                ),
                _buildSwipeInstructions(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider, dynamic currentAlbum) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentAlbum.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentAlbum.photoCount} photos à trier',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showAlbumSelector(context, appProvider),
                icon: const Icon(Icons.swap_horiz, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(context, currentAlbum),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, dynamic currentAlbum) {
    final progress = currentAlbum.photoCount > 0 ? 0.3 : 0.0; // Exemple de progression
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
        ),
      ],
    );
  }

  Widget _buildSwipeArea(BuildContext context, AppProvider appProvider, dynamic currentAlbum) {
    if (currentAlbum.photos.isEmpty) {
      return _buildEmptyState(context, appProvider);
    }

    final currentPhoto = currentAlbum.photos.first; // Première photo à traiter

    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: (details) => _onPanEnd(details, appProvider, currentPhoto),
            child: AnimatedBuilder(
              animation: _swipeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: _dragOffset,
                  child: Transform.rotate(
                    angle: _dragOffset.dx * 0.001,
                    child: _PhotoCard(
                      photo: currentPhoto,
                      isDragging: _isDragging,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_currentDirection != null)
          AnimatedBuilder(
            animation: _overlayAnimation,
            builder: (context, child) {
              return _SwipeOverlay(
                direction: _currentDirection!,
                opacity: _overlayAnimation.value,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSwipeInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InstructionItem(
            icon: Icons.arrow_back,
            label: 'Supprimer',
            color: AppConstants.swipeLeftColor,
          ),
          _InstructionItem(
            icon: Icons.arrow_upward,
            label: 'Album',
            color: AppConstants.swipeUpColor,
          ),
          _InstructionItem(
            icon: Icons.arrow_forward,
            label: 'Conserver',
            color: AppConstants.swipeRightColor,
          ),
          _InstructionItem(
            icon: Icons.arrow_downward,
            label: 'Annuler',
            color: AppConstants.swipeDownColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider appProvider) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppConstants.swipeRightColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Toutes les photos sont triées !',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sélectionnez un autre album ou importez de nouvelles photos.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => appProvider.setCurrentPageIndex(AppConstants.albumsPageIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Voir les albums',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });

    // Déterminer la direction du swipe
    SwipeDirection? newDirection;
    if (_dragOffset.dx.abs() > AppConstants.swipeThreshold) {
      newDirection = _dragOffset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else if (_dragOffset.dy.abs() > AppConstants.swipeThreshold) {
      newDirection = _dragOffset.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }

    if (newDirection != _currentDirection) {
      setState(() {
        _currentDirection = newDirection;
      });
      
      if (newDirection != null) {
        _overlayController.forward();
        _triggerHapticFeedback();
      } else {
        _overlayController.reverse();
      }
    }
  }

  void _onPanEnd(DragEndDetails details, AppProvider appProvider, Photo photo) {
    setState(() {
      _isDragging = false;
    });

    if (_currentDirection != null) {
      _performSwipeAction(appProvider, photo, _currentDirection!);
    }

    // Reset
    _swipeController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _currentDirection = null;
      });
      _swipeController.reset();
      _overlayController.reset();
    });
  }

  void _performSwipeAction(AppProvider appProvider, Photo photo, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.right:
        // Conserver - pas d'action nécessaire
        break;
      case SwipeDirection.left:
        appProvider.performSwipeAction(photo.id, direction);
        break;
      case SwipeDirection.up:
        _showAlbumSelectionDialog(appProvider, photo);
        return; // Ne pas effectuer l'action maintenant
      case SwipeDirection.down:
        appProvider.performSwipeAction(photo.id, direction);
        break;
    }

    if (direction != SwipeDirection.up) {
      appProvider.performSwipeAction(photo.id, direction);
    }
  }

  void _triggerHapticFeedback() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.hapticEnabled) {
      Vibration.vibrate(duration: 50);
    }
  }

  void _showAlbumSelector(BuildContext context, AppProvider appProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choisir un album',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...appProvider.albums.map((album) => ListTile(
              leading: Icon(
                album.type == AlbumType.all ? Icons.photo_library :
                album.type == AlbumType.favorites ? Icons.favorite :
                album.type == AlbumType.trash ? Icons.delete :
                Icons.folder,
                color: appProvider.currentAlbumId == album.id 
                    ? AppConstants.primaryColor 
                    : Colors.white70,
              ),
              title: Text(
                album.name,
                style: TextStyle(
                  color: appProvider.currentAlbumId == album.id 
                      ? AppConstants.primaryColor 
                      : Colors.white,
                ),
              ),
              subtitle: Text(
                '${album.photoCount} photos',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: appProvider.currentAlbumId == album.id
                  ? Icon(Icons.check, color: AppConstants.primaryColor)
                  : null,
              onTap: () {
                appProvider.setCurrentAlbum(album.id);
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _showAlbumSelectionDialog(AppProvider appProvider, Photo photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Ajouter à un album',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: appProvider.albums
              .where((album) => album.type != AlbumType.trash && album.id != appProvider.currentAlbumId)
              .map((album) => ListTile(
                leading: Icon(
                  album.type == AlbumType.favorites ? Icons.favorite : Icons.folder,
                  color: AppConstants.primaryColor,
                ),
                title: Text(
                  album.name,
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  appProvider.performSwipeAction(photo.id, SwipeDirection.up, targetAlbumId: album.id);
                  Navigator.pop(context);
                },
              )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final Photo photo;
  final bool isDragging;

  const _PhotoCard({
    required this.photo,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.3 : 0.2),
            blurRadius: isDragging ? 30 : 20,
            offset: Offset(0, isDragging ? 15 : 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image placeholder - dans une vraie app, utilisez Image.file(File(photo.path))
            Container(
              color: AppConstants.cardColor,
              child: Icon(
                Icons.image,
                size: 80,
                color: Colors.white38,
              ),
            ),
            // Overlay avec informations
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(photo.size / 1024 / 1024).toStringAsFixed(1)} MB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeOverlay extends StatelessWidget {
  final SwipeDirection direction;
  final double opacity;

  const _SwipeOverlay({
    required this.direction,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (direction) {
      case SwipeDirection.right:
        color = AppConstants.swipeRightColor;
        icon = Icons.check;
        text = 'CONSERVER';
        break;
      case SwipeDirection.left:
        color = AppConstants.swipeLeftColor;
        icon = Icons.delete;
        text = 'SUPPRIMER';
        break;
      case SwipeDirection.up:
        color = AppConstants.swipeUpColor;
        icon = Icons.folder;
        text = 'ALBUM';
        break;
      case SwipeDirection.down:
        color = AppConstants.swipeDownColor;
        icon = Icons.undo;
        text = 'ANNULER';
        break;
    }

    return Positioned.fill(
      child: Container(
        color: color.withOpacity(opacity * 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 60,
                color: Colors.white.withOpacity(opacity),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withOpacity(opacity),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InstructionItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
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