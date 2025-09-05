import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';
import '../models/album.dart';
import '../models/photo.dart';
import '../models/trash_item.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  Directory? _appDirectory;
  Directory? _albumsDirectory;
  Directory? _metadataDirectory;

  Future<void> initialize() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    _appDirectory = Directory(path.join(documentsDir.path, AppConstants.appFolderName));
    _albumsDirectory = Directory(path.join(_appDirectory!.path, AppConstants.albumsFolderName));
    _metadataDirectory = Directory(path.join(_appDirectory!.path, AppConstants.metadataFolderName));

    await _ensureDirectoriesExist();
    await _createDefaultAlbums();
  }

  Future<void> _ensureDirectoriesExist() async {
    if (!await _appDirectory!.exists()) {
      await _appDirectory!.create(recursive: true);
    }
    if (!await _albumsDirectory!.exists()) {
      await _albumsDirectory!.create(recursive: true);
    }
    if (!await _metadataDirectory!.exists()) {
      await _metadataDirectory!.create(recursive: true);
    }
  }

  Future<void> _createDefaultAlbums() async {
    final defaultAlbums = [
      Album(
        id: 'all_photos',
        name: AppConstants.allPhotosAlbumName,
        path: path.join(_albumsDirectory!.path, 'all_photos'),
        type: AlbumType.all,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      ),
      Album(
        id: 'favorites',
        name: AppConstants.favoritesAlbumName,
        path: path.join(_albumsDirectory!.path, 'favorites'),
        type: AlbumType.favorites,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      ),
      Album(
        id: 'trash',
        name: AppConstants.trashAlbumName,
        path: path.join(_albumsDirectory!.path, 'trash'),
        type: AlbumType.trash,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      ),
    ];

    for (final album in defaultAlbums) {
      final albumDir = Directory(album.path);
      if (!await albumDir.exists()) {
        await albumDir.create(recursive: true);
      }
    }
  }

  // Album Management
  Future<List<Album>> loadAlbums() async {
    final albumsFile = File(path.join(_metadataDirectory!.path, AppConstants.albumsJsonFile));
    
    if (!await albumsFile.exists()) {
      return await _getDefaultAlbums();
    }

    try {
      final jsonString = await albumsFile.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Album.fromJson(json)).toList();
    } catch (e) {
      print('Error loading albums: $e');
      return await _getDefaultAlbums();
    }
  }

  Future<void> saveAlbums(List<Album> albums) async {
    final albumsFile = File(path.join(_metadataDirectory!.path, AppConstants.albumsJsonFile));
    final jsonString = json.encode(albums.map((album) => album.toJson()).toList());
    await albumsFile.writeAsString(jsonString);
  }

  Future<Album> createAlbum(String name) async {
    final albumId = DateTime.now().millisecondsSinceEpoch.toString();
    final albumPath = path.join(_albumsDirectory!.path, albumId);
    
    final album = Album(
      id: albumId,
      name: name,
      path: albumPath,
      type: AlbumType.custom,
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
    );

    final albumDir = Directory(albumPath);
    await albumDir.create(recursive: true);

    return album;
  }

  Future<void> deleteAlbum(Album album) async {
    if (!album.canDelete) return;

    final albumDir = Directory(album.path);
    if (await albumDir.exists()) {
      await albumDir.delete(recursive: true);
    }
  }

  // Photo Management
  Future<List<Photo>> loadPhotosFromAlbum(String albumId) async {
    final albums = await loadAlbums();
    final album = albums.firstWhere((a) => a.id == albumId);
    
    final albumDir = Directory(album.path);
    if (!await albumDir.exists()) return [];

    final List<Photo> photos = [];
    await for (final entity in albumDir.list()) {
      if (entity is File && _isImageFile(entity.path)) {
        final stat = await entity.stat();
        final photo = Photo(
          id: path.basenameWithoutExtension(entity.path),
          path: entity.path,
          name: path.basename(entity.path),
          dateCreated: stat.changed,
          dateModified: stat.modified,
          size: stat.size,
          albumId: albumId,
        );
        photos.add(photo);
      }
    }

    return photos;
  }

  Future<void> movePhoto(Photo photo, String targetAlbumId) async {
    final albums = await loadAlbums();
    final targetAlbum = albums.firstWhere((a) => a.id == targetAlbumId);
    
    final sourceFile = File(photo.path);
    final targetPath = path.join(targetAlbum.path, photo.name);
    final targetFile = File(targetPath);

    if (await sourceFile.exists()) {
      await sourceFile.copy(targetPath);
      await sourceFile.delete();
    }
  }

  // Trash Management
  Future<List<TrashItem>> loadTrashItems() async {
    final trashFile = File(path.join(_metadataDirectory!.path, AppConstants.trashJsonFile));
    
    if (!await trashFile.exists()) return [];

    try {
      final jsonString = await trashFile.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => TrashItem.fromJson(json)).toList();
    } catch (e) {
      print('Error loading trash items: $e');
      return [];
    }
  }

  Future<void> saveTrashItems(List<TrashItem> items) async {
    final trashFile = File(path.join(_metadataDirectory!.path, AppConstants.trashJsonFile));
    final jsonString = json.encode(items.map((item) => item.toJson()).toList());
    await trashFile.writeAsString(jsonString);
  }

  Future<void> permanentlyDeletePhoto(Photo photo) async {
    final file = File(photo.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Helper Methods
  Future<List<Album>> _getDefaultAlbums() async {
    return [
      Album(
        id: 'all_photos',
        name: AppConstants.allPhotosAlbumName,
        path: path.join(_albumsDirectory!.path, 'all_photos'),
        type: AlbumType.all,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      ),
      Album(
        id: 'favorites',
        name: AppConstants.favoritesAlbumName,
        path: path.join(_albumsDirectory!.path, 'favorites'),
        type: AlbumType.favorites,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      ),
      Album(
        id: 'trash',
        name: AppConstants.trashAlbumName,
        path: path.join(_albumsDirectory!.path, 'trash'),
        type: AlbumType.trash,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      ),
    ];
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return AppConstants.supportedImageExtensions.contains(extension);
  }

  // Getters
  Directory get appDirectory => _appDirectory!;
  Directory get albumsDirectory => _albumsDirectory!;
  Directory get metadataDirectory => _metadataDirectory!;
}