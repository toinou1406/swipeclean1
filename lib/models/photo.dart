import 'dart:io';

class Photo {
  final String id;
  final String path;
  final String name;
  final DateTime dateCreated;
  final DateTime dateModified;
  final int size;
  final String albumId;
  final Map<String, dynamic>? metadata;

  Photo({
    required this.id,
    required this.path,
    required this.name,
    required this.dateCreated,
    required this.dateModified,
    required this.size,
    required this.albumId,
    this.metadata,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      dateCreated: DateTime.parse(json['dateCreated']),
      dateModified: DateTime.parse(json['dateModified']),
      size: json['size'],
      albumId: json['albumId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'size': size,
      'albumId': albumId,
      'metadata': metadata,
    };
  }

  Photo copyWith({
    String? id,
    String? path,
    String? name,
    DateTime? dateCreated,
    DateTime? dateModified,
    int? size,
    String? albumId,
    Map<String, dynamic>? metadata,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      size: size ?? this.size,
      albumId: albumId ?? this.albumId,
      metadata: metadata ?? this.metadata,
    );
  }

  File get file => File(path);
  bool get exists => file.existsSync();
}