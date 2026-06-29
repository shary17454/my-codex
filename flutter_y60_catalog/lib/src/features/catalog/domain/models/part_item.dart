class PartItem {
  const PartItem({
    required this.id,
    required this.diagramId,
    required this.partNumber,
    required this.nameAr,
    required this.nameEn,
    required this.diagramReference,
    required this.quantity,
    required this.sourcePageNumber,
    required this.updatedAt,
    this.notesAr,
    this.compatibility,
    this.imagePath,
  });

  final String id;
  final String diagramId;
  final String partNumber;
  final String nameAr;
  final String nameEn;
  final String diagramReference;
  final int quantity;
  final int sourcePageNumber;
  final DateTime updatedAt;
  final String? notesAr;
  final String? compatibility;
  final String? imagePath;

  String get searchableText => [
        partNumber,
        nameAr,
        nameEn,
        diagramReference,
        notesAr,
        compatibility,
      ].whereType<String>().join(' ');

  factory PartItem.fromJson(Map<String, dynamic> json) {
    return PartItem(
      id: json['id'] as String,
      diagramId: json['diagramId'] as String,
      partNumber: json['partNumber'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      diagramReference: json['diagramReference'] as String,
      quantity: json['quantity'] as int,
      sourcePageNumber: json['sourcePageNumber'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notesAr: json['notesAr'] as String?,
      compatibility: json['compatibility'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diagramId': diagramId,
      'partNumber': partNumber,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'diagramReference': diagramReference,
      'quantity': quantity,
      'sourcePageNumber': sourcePageNumber,
      'updatedAt': updatedAt.toIso8601String(),
      'notesAr': notesAr,
      'compatibility': compatibility,
      'imagePath': imagePath,
    };
  }
}
