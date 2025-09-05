import 'dart:io';
import 'photo.dart';

enum AlbumType {
  all,
  favorites,
  trash,
  custom,
}

class Album {
  final String id;
  final String name;
  final String path;
  final AlbumType type;
  final DateTime dateCreated;
  final DateTime dateModified;
  final List<Photo> photos;
  final String? coverPhotoId;

  Album({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.dateCreated,
    required this.dateModified,
    this.photos = const [],
    this.coverPhotoId,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      type: AlbumType.values.firstWhere(
        (e) => e.toString() == 'AlbumType.${json['type']}',
        orElse: () => AlbumType.custom,
      ),
      dateCreated: DateTime.parse(json['dateCreated']),
      dateModified: DateTime.parse(json['dateModified']),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((photoJson) => Photo.fromJson(photoJson))
              .toList() ??
          [],
      coverPhotoId: json['coverPhotoId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.toString().split('.').last,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'coverPhotoId': coverPhotoId,
    };
  }

  Album copyWith({
    String? id,
    String? name,
    String? path,
    AlbumType? type,
    DateTime? dateCreated,
    DateTime? dateModified,
    List<Photo>? photos,
    String? coverPhotoId,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      photos: photos ?? this.photos,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
    );
  }

  Directory get directory => Directory(path);
  bool get exists => directory.existsSync();
  int get photoCount => photos.length;
  Photo? get coverPhoto => photos.isNotEmpty 
      ? photos.firstWhere(
          (photo) => photo.id == coverPhotoId,
          orElse: () => photos.first,
        )
      : null;

  bool get isSystemAlbum => type != AlbumType.custom;
  bool get canDelete => type == AlbumType.custom;
  bool get canRename => type == AlbumType.custom;
}