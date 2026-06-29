class CatalogPage {
  const CatalogPage({
    required this.id,
    required this.sectionId,
    required this.pageNumber,
    required this.titleAr,
    required this.titleEn,
    required this.sourcePdfPath,
    required this.pageImagePath,
    required this.updatedAt,
    this.extractedTextAr,
    this.extractedTextEn,
  });

  final String id;
  final String sectionId;
  final int pageNumber;
  final String titleAr;
  final String titleEn;
  final String sourcePdfPath;
  final String pageImagePath;
  final String? extractedTextAr;
  final String? extractedTextEn;
  final DateTime updatedAt;

  String get searchableText => [
        titleAr,
        titleEn,
        extractedTextAr,
        extractedTextEn,
      ].whereType<String>().join(' ');

  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    return CatalogPage(
      id: json['id'] as String,
      sectionId: json['sectionId'] as String,
      pageNumber: json['pageNumber'] as int,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      sourcePdfPath: json['sourcePdfPath'] as String,
      pageImagePath: json['pageImagePath'] as String,
      extractedTextAr: json['extractedTextAr'] as String?,
      extractedTextEn: json['extractedTextEn'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionId': sectionId,
      'pageNumber': pageNumber,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'sourcePdfPath': sourcePdfPath,
      'pageImagePath': pageImagePath,
      'extractedTextAr': extractedTextAr,
      'extractedTextEn': extractedTextEn,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
