import 'photo.dart';

class TrashItem {
  final Photo photo;
  final DateTime deletedAt;
  final String originalAlbumId;
  final Duration timeRemaining;

  TrashItem({
    required this.photo,
    required this.deletedAt,
    required this.originalAlbumId,
    required this.timeRemaining,
  });

  factory TrashItem.fromJson(Map<String, dynamic> json) {
    return TrashItem(
      photo: Photo.fromJson(json['photo']),
      deletedAt: DateTime.parse(json['deletedAt']),
      originalAlbumId: json['originalAlbumId'],
      timeRemaining: Duration(milliseconds: json['timeRemainingMs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo': photo.toJson(),
      'deletedAt': deletedAt.toIso8601String(),
      'originalAlbumId': originalAlbumId,
      'timeRemainingMs': timeRemaining.inMilliseconds,
    };
  }

  TrashItem copyWith({
    Photo? photo,
    DateTime? deletedAt,
    String? originalAlbumId,
    Duration? timeRemaining,
  }) {
    return TrashItem(
      photo: photo ?? this.photo,
      deletedAt: deletedAt ?? this.deletedAt,
      originalAlbumId: originalAlbumId ?? this.originalAlbumId,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }

  bool get isExpired => timeRemaining.inMilliseconds <= 0;
  bool get canRestore => !isExpired;
  
  String get timeRemainingFormatted {
    final minutes = timeRemaining.inMinutes;
    final seconds = timeRemaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}