import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/photo.dart';
import '../models/album.dart' as app_models;
import 'storage_service.dart';

class PhotoService {
  static PhotoService? _instance;
  static PhotoService get instance => _instance ??= PhotoService._();
  PhotoService._();

  final StorageService _storageService = StorageService.instance;

  Future<bool> requestPermissions() async {
    final storageStatus = await Permission.storage.request();
    final photosStatus = await Permission.photos.request();
    
    return storageStatus.isGranted && photosStatus.isGranted;
  }

  Future<List<AssetEntity>> getDevicePhotos() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final photos = await recentAlbum.getAssetListRange(
      start: 0,
      end: await recentAlbum.assetCountAsync,
    );

    return photos;
  }

  Future<void> importPhotosToApp() async {
    final devicePhotos = await getDevicePhotos();
    final allPhotosAlbum = (await _storageService.loadAlbums())
        .firstWhere((album) => album.type == app_models.AlbumType.all);

    for (final assetEntity in devicePhotos) {
      final file = await assetEntity.file;
      if (file == null) continue;

      final targetPath = '${allPhotosAlbum.path}/${assetEntity.title}';
      final targetFile = File(targetPath);

      if (!await targetFile.exists()) {
        await file.copy(targetPath);
      }
    }
  }

  Future<Photo?> getPhotoById(String photoId, String albumId) async {
    final photos = await _storageService.loadPhotosFromAlbum(albumId);
    try {
      return photos.firstWhere((photo) => photo.id == photoId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Photo>> getPhotosFromAlbum(String albumId) async {
    return await _storageService.loadPhotosFromAlbum(albumId);
  }

  Future<void> movePhotoToAlbum(Photo photo, String targetAlbumId) async {
    await _storageService.movePhoto(photo, targetAlbumId);
  }

  Future<void> deletePhoto(Photo photo) async {
    // Move to trash instead of permanent deletion
    await movePhotoToAlbum(photo, 'trash');
  }

  Future<void> restorePhotoFromTrash(Photo photo, String originalAlbumId) async {
    await movePhotoToAlbum(photo, originalAlbumId);
  }

  Future<void> permanentlyDeletePhoto(Photo photo) async {
    await _storageService.permanentlyDeletePhoto(photo);
  }

  Future<File?> getPhotoFile(Photo photo) async {
    final file = File(photo.path);
    return await file.exists() ? file : null;
  }

  Future<int> getAlbumPhotoCount(String albumId) async {
    final photos = await getPhotosFromAlbum(albumId);
    return photos.length;
  }

  Future<Photo?> getAlbumCoverPhoto(String albumId) async {
    final photos = await getPhotosFromAlbum(albumId);
    return photos.isNotEmpty ? photos.first : null;
  }

  Future<List<Photo>> searchPhotos(String query, {String? albumId}) async {
    List<Photo> photos;
    
    if (albumId != null) {
      photos = await getPhotosFromAlbum(albumId);
    } else {
      // Search in all albums
      final albums = await _storageService.loadAlbums();
      photos = [];
      for (final album in albums) {
        final albumPhotos = await getPhotosFromAlbum(album.id);
        photos.addAll(albumPhotos);
      }
    }

    return photos.where((photo) {
      return photo.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<Map<String, int>> getPhotoStatistics() async {
    final albums = await _storageService.loadAlbums();
    final Map<String, int> stats = {};

    for (final album in albums) {
      final count = await getAlbumPhotoCount(album.id);
      stats[album.name] = count;
    }

    return stats;
  }
}