import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../models/photo.dart';
import '../models/swipe_action.dart';
import '../models/trash_item.dart';
import '../services/storage_service.dart';
import '../services/photo_service.dart';
import '../services/trash_service.dart';
import '../services/statistics_service.dart';
import '../services/permission_service.dart';
import '../constants/app_constants.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  final PhotoService _photoService = PhotoService.instance;
  final TrashService _trashService = TrashService.instance;
  final StatisticsService _statisticsService = StatisticsService.instance;
  final PermissionService _permissionService = PermissionService.instance;

  // State
  List<Album> _albums = [];
  List<SwipeAction> _swipeHistory = [];
  List<TrashItem> _trashItems = [];
  int _currentPageIndex = AppConstants.homePageIndex;
  String? _currentAlbumId;
  bool _isLoading = false;
  bool _hapticEnabled = true;
  bool _soundEnabled = false;

  // Getters
  List<Album> get albums => _albums;
  List<SwipeAction> get swipeHistory => _swipeHistory;
  List<TrashItem> get trashItems => _trashItems;
  int get currentPageIndex => _currentPageIndex;
  String? get currentAlbumId => _currentAlbumId;
  bool get isLoading => _isLoading;
  bool get hapticEnabled => _hapticEnabled;
  bool get soundEnabled => _soundEnabled;

  Album? get currentAlbum => _currentAlbumId != null
      ? _albums.firstWhere(
          (album) => album.id == _currentAlbumId,
          orElse: () => _albums.first,
        )
      : null;

  Album get allPhotosAlbum => _albums.firstWhere(
        (album) => album.type == AlbumType.all,
      );

  Album get favoritesAlbum => _albums.firstWhere(
        (album) => album.type == AlbumType.favorites,
      );

  Album get trashAlbum => _albums.firstWhere(
        (album) => album.type == AlbumType.trash,
      );

  List<Album> get customAlbums => _albums
      .where((album) => album.type == AlbumType.custom)
      .toList();

  // Initialization
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      await _permissionService.initialize();
      await _storageService.initialize();
      await _trashService.initialize();
      await _statisticsService.initialize();
      await _loadAlbums();
      await _loadTrashItems();
      await _loadSettings();
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAlbums() async {
    _albums = await _storageService.loadAlbums();
    
    // Load photos for each album
    for (int i = 0; i < _albums.length; i++) {
      final photos = await _photoService.getPhotosFromAlbum(_albums[i].id);
      _albums[i] = _albums[i].copyWith(photos: photos);
    }
    
    notifyListeners();
  }

  Future<void> _loadTrashItems() async {
    _trashItems = _trashService.trashItems;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticEnabled = prefs.getBool(AppConstants.keyHapticEnabled) ?? true;
    _soundEnabled = prefs.getBool(AppConstants.keySoundEnabled) ?? false;
    _currentAlbumId = prefs.getString(AppConstants.keyCurrentAlbumId) ?? allPhotosAlbum.id;
    notifyListeners();
  }

  // Navigation
  void setCurrentPageIndex(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void setCurrentAlbum(String albumId) async {
    _currentAlbumId = albumId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentAlbumId, albumId);
    notifyListeners();
  }

  // Album Management
  Future<void> createAlbum(String name) async {
    _setLoading(true);
    
    try {
      final album = await _storageService.createAlbum(name);
      _albums.add(album);
      await _storageService.saveAlbums(_albums);
      notifyListeners();
    } catch (e) {
      print('Error creating album: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    final album = _albums.firstWhere((a) => a.id == albumId);
    if (!album.canDelete) return;

    _setLoading(true);
    
    try {
      await _storageService.deleteAlbum(album);
      _albums.removeWhere((a) => a.id == albumId);
      await _storageService.saveAlbums(_albums);
      
      if (_currentAlbumId == albumId) {
        _currentAlbumId = allPhotosAlbum.id;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting album: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> renameAlbum(String albumId, String newName) async {
    final albumIndex = _albums.indexWhere((a) => a.id == albumId);
    if (albumIndex == -1) return;

    final album = _albums[albumIndex];
    if (!album.canRename) return;

    _albums[albumIndex] = album.copyWith(
      name: newName,
      dateModified: DateTime.now(),
    );
    
    await _storageService.saveAlbums(_albums);
    notifyListeners();
  }

  // Photo Management
  Future<void> movePhotoToAlbum(String photoId, String sourceAlbumId, String targetAlbumId) async {
    final sourceAlbumIndex = _albums.indexWhere((a) => a.id == sourceAlbumId);
    final targetAlbumIndex = _albums.indexWhere((a) => a.id == targetAlbumId);
    
    if (sourceAlbumIndex == -1 || targetAlbumIndex == -1) return;

    final sourceAlbum = _albums[sourceAlbumIndex];
    final photo = sourceAlbum.photos.firstWhere((p) => p.id == photoId);
    
    await _photoService.movePhotoToAlbum(photo, targetAlbumId);
    
    // Update albums
    _albums[sourceAlbumIndex] = sourceAlbum.copyWith(
      photos: sourceAlbum.photos.where((p) => p.id != photoId).toList(),
    );
    
    final targetAlbum = _albums[targetAlbumIndex];
    final updatedPhoto = photo.copyWith(albumId: targetAlbumId);
    _albums[targetAlbumIndex] = targetAlbum.copyWith(
      photos: [...targetAlbum.photos, updatedPhoto],
    );
    
    notifyListeners();
  }

  // Swipe Actions
  Future<void> performSwipeAction(String photoId, SwipeDirection direction, {String? targetAlbumId}) async {
    final action = SwipeAction(
      photoId: photoId,
      direction: direction,
      timestamp: DateTime.now(),
      targetAlbumId: targetAlbumId,
      previousAlbumId: _currentAlbumId,
    );

    _swipeHistory.add(action);
    await _statisticsService.recordSwipeAction(action);

    switch (direction) {
      case SwipeDirection.right:
        // Keep photo - no action needed
        break;
      case SwipeDirection.left:
        await _movePhotoToTrash(photoId);
        break;
      case SwipeDirection.up:
        if (targetAlbumId != null) {
          await movePhotoToAlbum(photoId, _currentAlbumId!, targetAlbumId);
        }
        break;
      case SwipeDirection.down:
        await _undoLastAction();
        break;
    }

    notifyListeners();
  }

  Future<void> _movePhotoToTrash(String photoId) async {
    final currentAlbum = _albums.firstWhere((a) => a.id == _currentAlbumId);
    final photo = currentAlbum.photos.firstWhere((p) => p.id == photoId);
    
    await _trashService.addToTrash(photo, _currentAlbumId!);
    await movePhotoToAlbum(photoId, _currentAlbumId!, trashAlbum.id);
    _trashItems = _trashService.trashItems;
  }

  Future<void> _undoLastAction() async {
    if (_swipeHistory.isEmpty) return;
    
    final lastAction = _swipeHistory.removeLast();
    if (!lastAction.canUndo) return;

    // Implement undo logic based on action type
    switch (lastAction.direction) {
      case SwipeDirection.left:
        await _restoreFromTrash(lastAction.photoId, lastAction.previousAlbumId!);
        break;
      case SwipeDirection.up:
        if (lastAction.previousAlbumId != null && lastAction.targetAlbumId != null) {
          await movePhotoToAlbum(
            lastAction.photoId,
            lastAction.targetAlbumId!,
            lastAction.previousAlbumId!,
          );
        }
        break;
      default:
        break;
    }
  }

  // Trash Management
  Future<void> _restoreFromTrash(String photoId, String originalAlbumId) async {
    final trashItemIndex = _trashItems.indexWhere((item) => item.photo.id == photoId);
    if (trashItemIndex == -1) return;

    final trashItem = _trashItems[trashItemIndex];
    await _photoService.restorePhotoFromTrash(trashItem.photo, originalAlbumId);
    
    _trashItems.removeAt(trashItemIndex);
    await _storageService.saveTrashItems(_trashItems);
    await _loadAlbums(); // Refresh albums
  }

  Future<void> _startTrashTimer() async {
    // This would be implemented with a proper timer in a real app
    // For now, we'll just update on app start
    _updateTrashItemsTimer();
  }

  void _updateTrashItemsTimer() {
    final now = DateTime.now();
    final expiredItems = <TrashItem>[];
    
    for (int i = 0; i < _trashItems.length; i++) {
      final item = _trashItems[i];
      final elapsed = now.difference(item.deletedAt);
      final remaining = AppConstants.trashRetentionDuration - elapsed;
      
      if (remaining.inMilliseconds <= 0) {
        expiredItems.add(item);
      } else {
        _trashItems[i] = item.copyWith(timeRemaining: remaining);
      }
    }
    
    // Remove expired items
    for (final expiredItem in expiredItems) {
      _photoService.permanentlyDeletePhoto(expiredItem.photo);
      _trashItems.remove(expiredItem);
    }
    
    if (expiredItems.isNotEmpty) {
      _storageService.saveTrashItems(_trashItems);
    }
  }

  // Settings
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHapticEnabled, enabled);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySoundEnabled, enabled);
    notifyListeners();
  }

  // Helper Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> refreshAlbums() async {
    await _loadAlbums();
  }

  Future<void> refreshTrash() async {
    await _loadTrashItems();
  }

  // Service getters
  PermissionService get permissionService => _permissionService;
  TrashService get trashService => _trashService;
  StatisticsService get statisticsService => _statisticsService;

  // Statistics getters
  Map<String, dynamic> get statistics => _statisticsService.allStatistics;
  int get totalActionsToday => _statisticsService.totalActionsToday;
  int get sessionPhotosProcessed => _statisticsService.sessionPhotosProcessed;
  Duration get sessionDuration => _statisticsService.sessionDuration;
  Map<String, int> get dailyStatistics => _statisticsService.dailyStatistics;
  List<Map<String, dynamic>> get weeklyTrend => _statisticsService.weeklyTrend;
  Map<String, dynamic> get efficiency => _statisticsService.efficiency;

  // Permission getters
  bool get hasAllPermissions => _permissionService.hasAllRequiredPermissions;
  bool get hasStoragePermission => _permissionService.hasStoragePermission;
  bool get hasPhotosPermission => _permissionService.hasPhotosPermission;
}