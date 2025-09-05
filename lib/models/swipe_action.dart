enum SwipeDirection {
  right,  // Conserver
  left,   // Supprimer
  up,     // Ajouter à album
  down,   // Annuler
}

class SwipeAction {
  final String photoId;
  final SwipeDirection direction;
  final DateTime timestamp;
  final String? targetAlbumId;
  final String? previousAlbumId;

  SwipeAction({
    required this.photoId,
    required this.direction,
    required this.timestamp,
    this.targetAlbumId,
    this.previousAlbumId,
  });

  factory SwipeAction.fromJson(Map<String, dynamic> json) {
    return SwipeAction(
      photoId: json['photoId'],
      direction: SwipeDirection.values.firstWhere(
        (e) => e.toString() == 'SwipeDirection.${json['direction']}',
      ),
      timestamp: DateTime.parse(json['timestamp']),
      targetAlbumId: json['targetAlbumId'],
      previousAlbumId: json['previousAlbumId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoId': photoId,
      'direction': direction.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'targetAlbumId': targetAlbumId,
      'previousAlbumId': previousAlbumId,
    };
  }

  String get actionDescription {
    switch (direction) {
      case SwipeDirection.right:
        return 'Photo conservée';
      case SwipeDirection.left:
        return 'Photo supprimée';
      case SwipeDirection.up:
        return 'Photo ajoutée à un album';
      case SwipeDirection.down:
        return 'Action annulée';
    }
  }

  bool get canUndo => direction != SwipeDirection.down;
}