class CatalogSection {
  const CatalogSection({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.sortOrder,
    required this.sourceCatalogPath,
    this.descriptionAr,
    this.parentSectionId,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final int sortOrder;
  final String sourceCatalogPath;
  final String? descriptionAr;
  final String? parentSectionId;

  String get searchableText => [
        titleAr,
        titleEn,
        descriptionAr,
      ].whereType<String>().join(' ');

  factory CatalogSection.fromJson(Map<String, dynamic> json) {
    return CatalogSection(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      sortOrder: json['sortOrder'] as int,
      sourceCatalogPath: json['sourceCatalogPath'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      parentSectionId: json['parentSectionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'sortOrder': sortOrder,
      'sourceCatalogPath': sourceCatalogPath,
      'descriptionAr': descriptionAr,
      'parentSectionId': parentSectionId,
    };
  }
}
