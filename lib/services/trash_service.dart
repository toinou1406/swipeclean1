import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/trash_item.dart';
import '../models/photo.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class TrashService {
  static TrashService? _instance;
  static TrashService get instance => _instance ??= TrashService._();
  TrashService._();

  final StorageService _storageService = StorageService.instance;
  Timer? _cleanupTimer;
  final List<TrashItem> _trashItems = [];
  final StreamController<List<TrashItem>> _trashController = StreamController<List<TrashItem>>.broadcast();

  Stream<List<TrashItem>> get trashStream => _trashController.stream;
  List<TrashItem> get trashItems => List.unmodifiable(_trashItems);

  Future<void> initialize() async {
    await _loadTrashItems();
    _startCleanupTimer();
  }

  Future<void> _loadTrashItems() async {
    try {
      final trashFile = File(path.join(
        _storageService.metadataDirectory.path,
        AppConstants.trashJsonFile,
      ));

      if (!await trashFile.exists()) {
        _trashItems.clear();
        _trashController.add(_trashItems);
        return;
      }

      final jsonString = await trashFile.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _trashItems.clear();
      for (final jsonItem in jsonList) {
        try {
          final trashItem = TrashItem.fromJson(jsonItem);
          _trashItems.add(trashItem);
        } catch (e) {
          print('Error parsing trash item: $e');
        }
      }

      _updateTimers();
      _trashController.add(_trashItems);
    } catch (e) {
      print('Error loading trash items: $e');
      _trashItems.clear();
      _trashController.add(_trashItems);
    }
  }

  Future<void> _saveTrashItems() async {
    try {
      final trashFile = File(path.join(
        _storageService.metadataDirectory.path,
        AppConstants.trashJsonFile,
      ));

      final jsonString = json.encode(
        _trashItems.map((item) => item.toJson()).toList(),
      );
      
      await trashFile.writeAsString(jsonString);
    } catch (e) {
      print('Error saving trash items: $e');
    }
  }

  Future<void> addToTrash(Photo photo, String originalAlbumId) async {
    final now = DateTime.now();
    final trashItem = TrashItem(
      photo: photo,
      deletedAt: now,
      originalAlbumId: originalAlbumId,
      timeRemaining: AppConstants.trashRetentionDuration,
    );

    _trashItems.add(trashItem);
    await _saveTrashItems();
    _trashController.add(_trashItems);

    print('Photo ${photo.name} added to trash. Will be deleted in ${AppConstants.trashRetentionDuration.inMinutes} minutes.');
  }

  Future<bool> restoreFromTrash(String photoId) async {
    final itemIndex = _trashItems.indexWhere((item) => item.photo.id == photoId);
    if (itemIndex == -1) return false;

    final trashItem = _trashItems[itemIndex];
    if (trashItem.isExpired) return false;

    _trashItems.removeAt(itemIndex);
    await _saveTrashItems();
    _trashController.add(_trashItems);

    print('Photo ${trashItem.photo.name} restored from trash.');
    return true;
  }

  Future<void> permanentlyDelete(String photoId) async {
    final itemIndex = _trashItems.indexWhere((item) => item.photo.id == photoId);
    if (itemIndex == -1) return;

    final trashItem = _trashItems[itemIndex];
    
    // Delete physical file
    final file = File(trashItem.photo.path);
    if (await file.exists()) {
      try {
        await file.delete();
        print('Physical file deleted: ${trashItem.photo.path}');
      } catch (e) {
        print('Error deleting physical file: $e');
      }
    }

    _trashItems.removeAt(itemIndex);
    await _saveTrashItems();
    _trashController.add(_trashItems);

    print('Photo ${trashItem.photo.name} permanently deleted.');
  }

  Future<void> emptyTrash() async {
    final itemsToDelete = List<TrashItem>.from(_trashItems);
    
    for (final item in itemsToDelete) {
      await permanentlyDelete(item.photo.id);
    }

    print('Trash emptied. ${itemsToDelete.length} items permanently deleted.');
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      AppConstants.trashTimerUpdateInterval,
      (timer) => _updateTimers(),
    );
  }

  void _updateTimers() {
    final now = DateTime.now();
    final expiredItems = <TrashItem>[];
    final updatedItems = <TrashItem>[];

    for (final item in _trashItems) {
      final elapsed = now.difference(item.deletedAt);
      final remaining = AppConstants.trashRetentionDuration - elapsed;

      if (remaining.inMilliseconds <= 0) {
        expiredItems.add(item);
      } else {
        updatedItems.add(item.copyWith(timeRemaining: remaining));
      }
    }

    // Update items with new remaining time
    _trashItems.clear();
    _trashItems.addAll(updatedItems);

    // Permanently delete expired items
    if (expiredItems.isNotEmpty) {
      _deleteExpiredItems(expiredItems);
    }

    _trashController.add(_trashItems);
  }

  Future<void> _deleteExpiredItems(List<TrashItem> expiredItems) async {
    for (final item in expiredItems) {
      final file = File(item.photo.path);
      if (await file.exists()) {
        try {
          await file.delete();
          print('Expired photo deleted: ${item.photo.name}');
        } catch (e) {
          print('Error deleting expired photo: $e');
        }
      }
    }

    await _saveTrashItems();
    print('${expiredItems.length} expired items automatically deleted.');
  }

  Future<void> pauseTimer() async {
    _cleanupTimer?.cancel();
    print('Trash timer paused.');
  }

  Future<void> resumeTimer() async {
    _startCleanupTimer();
    print('Trash timer resumed.');
  }

  TrashItem? getTrashItem(String photoId) {
    try {
      return _trashItems.firstWhere((item) => item.photo.id == photoId);
    } catch (e) {
      return null;
    }
  }

  int get itemCount => _trashItems.length;
  
  bool get isEmpty => _trashItems.isEmpty;
  
  bool get isNotEmpty => _trashItems.isNotEmpty;

  Duration get nextExpirationTime {
    if (_trashItems.isEmpty) return Duration.zero;
    
    return _trashItems
        .map((item) => item.timeRemaining)
        .reduce((a, b) => a < b ? a : b);
  }

  List<TrashItem> get itemsExpiringSoon {
    const soonThreshold = Duration(minutes: 2);
    return _trashItems
        .where((item) => item.timeRemaining <= soonThreshold)
        .toList();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _trashController.close();
  }

  // Statistics
  Map<String, dynamic> getStatistics() {
    final totalSize = _trashItems.fold<int>(
      0,
      (sum, item) => sum + item.photo.size,
    );

    return {
      'itemCount': _trashItems.length,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'oldestItem': _trashItems.isNotEmpty
          ? _trashItems
              .reduce((a, b) => a.deletedAt.isBefore(b.deletedAt) ? a : b)
              .deletedAt
          : null,
      'newestItem': _trashItems.isNotEmpty
          ? _trashItems
              .reduce((a, b) => a.deletedAt.isAfter(b.deletedAt) ? a : b)
              .deletedAt
          : null,
      'nextExpiration': nextExpirationTime,
      'itemsExpiringSoon': itemsExpiringSoon.length,
    };
  }
}