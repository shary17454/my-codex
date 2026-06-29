class PartDiagram {
  const PartDiagram({
    required this.id,
    required this.catalogPageId,
    required this.titleAr,
    required this.titleEn,
    required this.diagramCode,
    required this.imagePath,
    required this.sourceBounds,
    required this.updatedAt,
  });

  final String id;
  final String catalogPageId;
  final String titleAr;
  final String titleEn;
  final String diagramCode;
  final String imagePath;
  final DiagramBounds sourceBounds;
  final DateTime updatedAt;

  String get searchableText => [
        titleAr,
        titleEn,
        diagramCode,
      ].join(' ');

  factory PartDiagram.fromJson(Map<String, dynamic> json) {
    return PartDiagram(
      id: json['id'] as String,
      catalogPageId: json['catalogPageId'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      diagramCode: json['diagramCode'] as String,
      imagePath: json['imagePath'] as String,
      sourceBounds: DiagramBounds.fromJson(
        json['sourceBounds'] as Map<String, dynamic>,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catalogPageId': catalogPageId,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'diagramCode': diagramCode,
      'imagePath': imagePath,
      'sourceBounds': sourceBounds.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class DiagramBounds {
  const DiagramBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  factory DiagramBounds.fromJson(Map<String, dynamic> json) {
    return DiagramBounds(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
