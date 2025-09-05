import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/swipe_action.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class StatisticsService {
  static StatisticsService? _instance;
  static StatisticsService get instance => _instance ??= StatisticsService._();
  StatisticsService._();

  final StorageService _storageService = StorageService.instance;
  
  // Statistics data
  Map<String, dynamic> _statistics = {};
  List<SwipeAction> _swipeHistory = [];
  
  // Progress tracking
  Map<String, int> _albumProgress = {};
  int _totalPhotosProcessed = 0;
  int _sessionPhotosProcessed = 0;
  DateTime? _sessionStartTime;

  Future<void> initialize() async {
    await _loadStatistics();
    await _loadSwipeHistory();
    _sessionStartTime = DateTime.now();
    _sessionPhotosProcessed = 0;
  }

  Future<void> _loadStatistics() async {
    try {
      final statsFile = File(path.join(
        _storageService.metadataDirectory.path,
        AppConstants.statisticsJsonFile,
      ));

      if (await statsFile.exists()) {
        final jsonString = await statsFile.readAsString();
        _statistics = json.decode(jsonString);
      } else {
        _statistics = _getDefaultStatistics();
      }
    } catch (e) {
      print('Error loading statistics: $e');
      _statistics = _getDefaultStatistics();
    }
  }

  Future<void> _saveStatistics() async {
    try {
      final statsFile = File(path.join(
        _storageService.metadataDirectory.path,
        AppConstants.statisticsJsonFile,
      ));

      final jsonString = json.encode(_statistics);
      await statsFile.writeAsString(jsonString);
    } catch (e) {
      print('Error saving statistics: $e');
    }
  }

  Future<void> _loadSwipeHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('swipe_history');
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _swipeHistory = historyList
            .map((json) => SwipeAction.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading swipe history: $e');
      _swipeHistory = [];
    }
  }

  Future<void> _saveSwipeHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _swipeHistory.map((action) => action.toJson()).toList(),
      );
      await prefs.setString('swipe_history', historyJson);
    } catch (e) {
      print('Error saving swipe history: $e');
    }
  }

  // Record swipe action
  Future<void> recordSwipeAction(SwipeAction action) async {
    _swipeHistory.add(action);
    _sessionPhotosProcessed++;
    _totalPhotosProcessed++;

    // Update statistics
    _updateSwipeStatistics(action);
    
    // Keep only last 1000 actions to prevent memory issues
    if (_swipeHistory.length > 1000) {
      _swipeHistory = _swipeHistory.sublist(_swipeHistory.length - 1000);
    }

    await _saveSwipeHistory();
    await _saveStatistics();
  }

  void _updateSwipeStatistics(SwipeAction action) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Daily statistics
    _statistics['daily'] ??= {};
    _statistics['daily'][today] ??= {
      'total': 0,
      'kept': 0,
      'deleted': 0,
      'moved': 0,
      'undone': 0,
    };

    _statistics['daily'][today]['total']++;
    
    switch (action.direction) {
      case SwipeDirection.right:
        _statistics['daily'][today]['kept']++;
        _statistics['totalKept'] = (_statistics['totalKept'] ?? 0) + 1;
        break;
      case SwipeDirection.left:
        _statistics['daily'][today]['deleted']++;
        _statistics['totalDeleted'] = (_statistics['totalDeleted'] ?? 0) + 1;
        break;
      case SwipeDirection.up:
        _statistics['daily'][today]['moved']++;
        _statistics['totalMoved'] = (_statistics['totalMoved'] ?? 0) + 1;
        break;
      case SwipeDirection.down:
        _statistics['daily'][today]['undone']++;
        _statistics['totalUndone'] = (_statistics['totalUndone'] ?? 0) + 1;
        break;
    }

    // Overall statistics
    _statistics['totalActions'] = (_statistics['totalActions'] ?? 0) + 1;
    _statistics['lastActionDate'] = DateTime.now().toIso8601String();
    
    // Session statistics
    _statistics['currentSession'] = {
      'startTime': _sessionStartTime?.toIso8601String(),
      'photosProcessed': _sessionPhotosProcessed,
      'duration': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inMinutes
          : 0,
    };
  }

  // Progress tracking
  Future<void> updateAlbumProgress(String albumId, int processedCount, int totalCount) async {
    _albumProgress[albumId] = processedCount;
    
    _statistics['albumProgress'] ??= {};
    _statistics['albumProgress'][albumId] = {
      'processed': processedCount,
      'total': totalCount,
      'percentage': totalCount > 0 ? (processedCount / totalCount * 100).round() : 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await _saveStatistics();
  }

  // Getters for statistics
  Map<String, dynamic> get allStatistics => Map.from(_statistics);
  
  List<SwipeAction> get swipeHistory => List.from(_swipeHistory);
  
  int get totalActionsToday {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _statistics['daily']?[today]?['total'] ?? 0;
  }

  int get totalActions => _statistics['totalActions'] ?? 0;
  
  int get totalKept => _statistics['totalKept'] ?? 0;
  
  int get totalDeleted => _statistics['totalDeleted'] ?? 0;
  
  int get totalMoved => _statistics['totalMoved'] ?? 0;
  
  int get totalUndone => _statistics['totalUndone'] ?? 0;

  int get sessionPhotosProcessed => _sessionPhotosProcessed;
  
  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!)
      : Duration.zero;

  double getAlbumProgress(String albumId) {
    final progress = _statistics['albumProgress']?[albumId];
    if (progress == null) return 0.0;
    return (progress['percentage'] ?? 0).toDouble() / 100.0;
  }

  Map<String, int> get dailyStatistics {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final daily = _statistics['daily']?[today];
    if (daily == null) return {};
    
    return {
      'total': daily['total'] ?? 0,
      'kept': daily['kept'] ?? 0,
      'deleted': daily['deleted'] ?? 0,
      'moved': daily['moved'] ?? 0,
      'undone': daily['undone'] ?? 0,
    };
  }

  List<Map<String, dynamic>> get weeklyTrend {
    final List<Map<String, dynamic>> trend = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final daily = _statistics['daily']?[dateStr];
      
      trend.add({
        'date': dateStr,
        'dayName': _getDayName(date.weekday),
        'total': daily?['total'] ?? 0,
        'kept': daily?['kept'] ?? 0,
        'deleted': daily?['deleted'] ?? 0,
        'moved': daily?['moved'] ?? 0,
      });
    }
    
    return trend;
  }

  Map<String, dynamic> get efficiency {
    if (totalActions == 0) return {'rate': 0.0, 'accuracy': 0.0};
    
    final sessionMinutes = sessionDuration.inMinutes;
    final rate = sessionMinutes > 0 ? sessionPhotosProcessed / sessionMinutes : 0.0;
    final accuracy = totalActions > 0 ? (totalActions - totalUndone) / totalActions : 0.0;
    
    return {
      'rate': rate, // photos per minute
      'accuracy': accuracy, // percentage of actions not undone
      'sessionRate': rate,
      'overallRate': totalActions > 0 ? totalActions / (_getAppUsageDays() * 24 * 60) : 0.0,
    };
  }

  List<SwipeAction> getRecentActions({int limit = 10}) {
    return _swipeHistory.reversed.take(limit).toList();
  }

  Map<String, dynamic> getActionDistribution() {
    if (totalActions == 0) {
      return {
        'kept': 0.0,
        'deleted': 0.0,
        'moved': 0.0,
        'undone': 0.0,
      };
    }

    return {
      'kept': totalKept / totalActions,
      'deleted': totalDeleted / totalActions,
      'moved': totalMoved / totalActions,
      'undone': totalUndone / totalActions,
    };
  }

  // Reset statistics
  Future<void> resetStatistics() async {
    _statistics = _getDefaultStatistics();
    _swipeHistory.clear();
    _albumProgress.clear();
    _totalPhotosProcessed = 0;
    _sessionPhotosProcessed = 0;
    _sessionStartTime = DateTime.now();
    
    await _saveStatistics();
    await _saveSwipeHistory();
  }

  Future<void> resetSessionStatistics() async {
    _sessionPhotosProcessed = 0;
    _sessionStartTime = DateTime.now();
    
    _statistics['currentSession'] = {
      'startTime': _sessionStartTime?.toIso8601String(),
      'photosProcessed': 0,
      'duration': 0,
    };
    
    await _saveStatistics();
  }

  // Helper methods
  Map<String, dynamic> _getDefaultStatistics() {
    return {
      'totalActions': 0,
      'totalKept': 0,
      'totalDeleted': 0,
      'totalMoved': 0,
      'totalUndone': 0,
      'firstUseDate': DateTime.now().toIso8601String(),
      'lastActionDate': null,
      'daily': {},
      'albumProgress': {},
      'currentSession': {
        'startTime': DateTime.now().toIso8601String(),
        'photosProcessed': 0,
        'duration': 0,
      },
    };
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }

  int _getAppUsageDays() {
    final firstUse = _statistics['firstUseDate'];
    if (firstUse == null) return 1;
    
    try {
      final firstUseDate = DateTime.parse(firstUse);
      return DateTime.now().difference(firstUseDate).inDays + 1;
    } catch (e) {
      return 1;
    }
  }

  // Export statistics
  Future<String> exportStatistics() async {
    final exportData = {
      'statistics': _statistics,
      'swipeHistory': _swipeHistory.map((action) => action.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': AppConstants.appVersion,
    };

    return json.encode(exportData);
  }

  // Import statistics
  Future<bool> importStatistics(String jsonData) async {
    try {
      final importData = json.decode(jsonData);
      
      if (importData['statistics'] != null) {
        _statistics = importData['statistics'];
      }
      
      if (importData['swipeHistory'] != null) {
        _swipeHistory = (importData['swipeHistory'] as List)
            .map((json) => SwipeAction.fromJson(json))
            .toList();
      }

      await _saveStatistics();
      await _saveSwipeHistory();
      
      return true;
    } catch (e) {
      print('Error importing statistics: $e');
      return false;
    }
  }
}