enum CommonIssueSeverity {
  info,
  low,
  medium,
  high,
}

class CommonIssue {
  const CommonIssue({
    required this.id,
    required this.vehicleProfileId,
    required this.titleAr,
    required this.symptomsAr,
    required this.relatedPartItemIds,
    required this.severity,
    required this.updatedAt,
    this.recommendedActionAr,
    this.sourceCatalogPageIds,
  });

  final String id;
  final String vehicleProfileId;
  final String titleAr;
  final String symptomsAr;
  final String? recommendedActionAr;
  final List<String> relatedPartItemIds;
  final List<String>? sourceCatalogPageIds;
  final CommonIssueSeverity severity;
  final DateTime updatedAt;

  String get searchableText => [
        titleAr,
        symptomsAr,
        recommendedActionAr,
      ].whereType<String>().join(' ');

  factory CommonIssue.fromJson(Map<String, dynamic> json) {
    return CommonIssue(
      id: json['id'] as String,
      vehicleProfileId: json['vehicleProfileId'] as String,
      titleAr: json['titleAr'] as String,
      symptomsAr: json['symptomsAr'] as String,
      recommendedActionAr: json['recommendedActionAr'] as String?,
      relatedPartItemIds: List<String>.from(json['relatedPartItemIds'] as List),
      sourceCatalogPageIds: json['sourceCatalogPageIds'] == null
          ? null
          : List<String>.from(json['sourceCatalogPageIds'] as List),
      severity: CommonIssueSeverity.values.byName(json['severity'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleProfileId': vehicleProfileId,
      'titleAr': titleAr,
      'symptomsAr': symptomsAr,
      'recommendedActionAr': recommendedActionAr,
      'relatedPartItemIds': relatedPartItemIds,
      'sourceCatalogPageIds': sourceCatalogPageIds,
      'severity': severity.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
