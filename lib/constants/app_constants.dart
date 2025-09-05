import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'SwipeClean';
  static const String appVersion = '1.0.0';

  // Storage
  static const String appFolderName = 'SwipeClean';
  static const String albumsFolderName = 'Albums';
  static const String metadataFolderName = 'Metadata';
  
  // Default Albums
  static const String allPhotosAlbumName = 'Toutes mes photos';
  static const String favoritesAlbumName = 'Mes préférés';
  static const String trashAlbumName = 'Corbeille';
  
  // Trash System
  static const Duration trashRetentionDuration = Duration(minutes: 10);
  static const Duration trashTimerUpdateInterval = Duration(seconds: 1);
  
  // Swipe Settings
  static const double swipeThreshold = 100.0;
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);
  static const Duration hapticFeedbackDelay = Duration(milliseconds: 50);
  
  // UI Constants
  static const double navigationBarHeight = 80.0;
  static const double navigationBarRadius = 40.0;
  static const EdgeInsets navigationBarPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
  
  // Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color cardColor = Color(0xFF334155);
  
  // Swipe Colors
  static const Color swipeRightColor = Color(0xFF10B981); // Vert - Conserver
  static const Color swipeLeftColor = Color(0xFFEF4444);  // Rouge - Supprimer
  static const Color swipeUpColor = Color(0xFF3B82F6);    // Bleu - Album
  static const Color swipeDownColor = Color(0xFFF59E0B);  // Orange - Annuler
  
  // Animation Curves
  static const Curve defaultAnimationCurve = Curves.easeInOut;
  static const Curve swipeAnimationCurve = Curves.elasticOut;
  
  // File Extensions
  static const List<String> supportedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.svg'
  ];
  
  // JSON Files
  static const String albumsJsonFile = 'albums.json';
  static const String settingsJsonFile = 'settings.json';
  static const String statisticsJsonFile = 'statistics.json';
  static const String trashJsonFile = 'trash.json';
  
  // App Info
  static const String appVersion = '1.0.0';
  
  // SharedPreferences Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyCurrentAlbumId = 'current_album_id';
  static const String keySwipeProgress = 'swipe_progress';
  static const String keyHapticEnabled = 'haptic_enabled';
  static const String keySoundEnabled = 'sound_enabled';
  
  // Navigation
  static const int homePageIndex = 1;
  static const int albumsPageIndex = 0;
  static const int swipePageIndex = 2;
}