import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  PermissionService._();

  // Permission status
  bool _storagePermissionGranted = false;
  bool _photosPermissionGranted = false;
  bool _manageExternalStorageGranted = false;

  // Getters
  bool get hasStoragePermission => _storagePermissionGranted;
  bool get hasPhotosPermission => _photosPermissionGranted;
  bool get hasManageExternalStoragePermission => _manageExternalStorageGranted;
  bool get hasAllRequiredPermissions => 
      _storagePermissionGranted && _photosPermissionGranted;

  Future<void> initialize() async {
    await _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    if (Platform.isAndroid) {
      _storagePermissionGranted = await Permission.storage.isGranted;
      _photosPermissionGranted = await Permission.photos.isGranted;
      
      // Check for Android 11+ manage external storage permission
      if (Platform.isAndroid) {
        _manageExternalStorageGranted = await Permission.manageExternalStorage.isGranted;
      }
    } else if (Platform.isIOS) {
      _photosPermissionGranted = await Permission.photos.isGranted;
      _storagePermissionGranted = true; // iOS doesn't need explicit storage permission
    }
  }

  Future<bool> requestAllPermissions() async {
    bool allGranted = true;

    if (Platform.isAndroid) {
      // Request storage permission
      final storageStatus = await Permission.storage.request();
      _storagePermissionGranted = storageStatus.isGranted;
      if (!_storagePermissionGranted) allGranted = false;

      // Request photos permission
      final photosStatus = await Permission.photos.request();
      _photosPermissionGranted = photosStatus.isGranted;
      if (!_photosPermissionGranted) allGranted = false;

      // For Android 11+, request manage external storage if needed
      if (Platform.isAndroid) {
        final manageStorageStatus = await Permission.manageExternalStorage.request();
        _manageExternalStorageGranted = manageStorageStatus.isGranted;
      }

    } else if (Platform.isIOS) {
      // Request photos permission for iOS
      final photosStatus = await Permission.photos.request();
      _photosPermissionGranted = photosStatus.isGranted;
      _storagePermissionGranted = true; // iOS doesn't need explicit storage permission
      if (!_photosPermissionGranted) allGranted = false;
    }

    return allGranted;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      _storagePermissionGranted = status.isGranted;
      return _storagePermissionGranted;
    }
    return true; // iOS doesn't need explicit storage permission
  }

  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    _photosPermissionGranted = status.isGranted;
    return _photosPermissionGranted;
  }

  Future<bool> requestManageExternalStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      _manageExternalStorageGranted = status.isGranted;
      return _manageExternalStorageGranted;
    }
    return true; // Not needed on iOS
  }

  Future<PermissionState> requestPhotoManagerPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps;
  }

  Future<bool> checkPhotoManagerPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  String getPermissionStatusMessage() {
    if (hasAllRequiredPermissions) {
      return 'Toutes les permissions sont accordées';
    }

    List<String> missingPermissions = [];
    
    if (!_storagePermissionGranted) {
      missingPermissions.add('Stockage');
    }
    
    if (!_photosPermissionGranted) {
      missingPermissions.add('Photos');
    }

    return 'Permissions manquantes: ${missingPermissions.join(', ')}';
  }

  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  Map<String, bool> getPermissionStatus() {
    return {
      'storage': _storagePermissionGranted,
      'photos': _photosPermissionGranted,
      'manageExternalStorage': _manageExternalStorageGranted,
      'allRequired': hasAllRequiredPermissions,
    };
  }

  Future<void> refreshPermissionStatus() async {
    await _checkCurrentPermissions();
  }

  // Helper methods for specific permission checks
  Future<bool> canAccessPhotos() async {
    if (!_photosPermissionGranted) {
      return await requestPhotosPermission();
    }
    return true;
  }

  Future<bool> canAccessStorage() async {
    if (!_storagePermissionGranted) {
      return await requestStoragePermission();
    }
    return true;
  }

  Future<bool> canManageFiles() async {
    if (Platform.isAndroid) {
      // For Android 11+, we might need manage external storage permission
      // for full file management capabilities
      if (!_manageExternalStorageGranted) {
        return await requestManageExternalStoragePermission();
      }
    }
    return hasAllRequiredPermissions;
  }

  // Permission explanation messages
  String getStoragePermissionExplanation() {
    return 'SwipeClean a besoin d\'accéder au stockage pour organiser vos photos dans des dossiers.';
  }

  String getPhotosPermissionExplanation() {
    return 'SwipeClean a besoin d\'accéder à vos photos pour vous permettre de les trier et organiser.';
  }

  String getManageExternalStorageExplanation() {
    return 'Pour une gestion complète des fichiers sur Android 11+, SwipeClean a besoin de la permission de gestion du stockage externe.';
  }

  // Check if we should show rationale
  Future<bool> shouldShowStorageRationale() async {
    if (Platform.isAndroid) {
      return await Permission.storage.shouldShowRequestRationale;
    }
    return false;
  }

  Future<bool> shouldShowPhotosRationale() async {
    return await Permission.photos.shouldShowRequestRationale;
  }

  // Permission denied permanently check
  Future<bool> isStoragePermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status.isPermanentlyDenied;
    }
    return false;
  }

  Future<bool> isPhotosPermissionPermanentlyDenied() async {
    final status = await Permission.photos.status;
    return status.isPermanentlyDenied;
  }
}