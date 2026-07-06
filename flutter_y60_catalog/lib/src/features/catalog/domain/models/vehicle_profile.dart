class VehicleProfile {
  const VehicleProfile({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.chassisPrefix,
    required this.chassisNumber,
    required this.modelCode,
    required this.productionDate,
    required this.registrationModelYear,
    required this.engineCode,
    required this.engineDescriptionAr,
    required this.transmissionCode,
    required this.transmissionDescriptionAr,
    required this.finalDriveCode,
    required this.bodyStyleAr,
    required this.exteriorColorCode,
    required this.interiorColorCode,
    required this.driveSide,
    required this.market,
    required this.sourceCatalogPath,
    required this.updatedAt,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String chassisPrefix;
  final String chassisNumber;
  final String modelCode;
  final DateTime productionDate;
  final int registrationModelYear;
  final String engineCode;
  final String engineDescriptionAr;
  final String transmissionCode;
  final String transmissionDescriptionAr;
  final String finalDriveCode;
  final String bodyStyleAr;
  final String exteriorColorCode;
  final String interiorColorCode;
  final String driveSide;
  final String market;
  final String sourceCatalogPath;
  final DateTime updatedAt;

  String get searchableText => [
        nameAr,
        nameEn,
        chassisPrefix,
        chassisNumber,
        modelCode,
        engineCode,
        transmissionCode,
        finalDriveCode,
        bodyStyleAr,
        exteriorColorCode,
        interiorColorCode,
        market,
      ].join(' ');

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      chassisPrefix: json['chassisPrefix'] as String,
      chassisNumber: json['chassisNumber'] as String,
      modelCode: json['modelCode'] as String,
      productionDate: DateTime.parse(json['productionDate'] as String),
      registrationModelYear: json['registrationModelYear'] as int,
      engineCode: json['engineCode'] as String,
      engineDescriptionAr: json['engineDescriptionAr'] as String,
      transmissionCode: json['transmissionCode'] as String,
      transmissionDescriptionAr: json['transmissionDescriptionAr'] as String,
      finalDriveCode: json['finalDriveCode'] as String? ?? '',
      bodyStyleAr: json['bodyStyleAr'] as String? ?? '',
      exteriorColorCode: json['exteriorColorCode'] as String? ?? '',
      interiorColorCode: json['interiorColorCode'] as String? ?? '',
      driveSide: json['driveSide'] as String,
      market: json['market'] as String,
      sourceCatalogPath: json['sourceCatalogPath'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'chassisPrefix': chassisPrefix,
      'chassisNumber': chassisNumber,
      'modelCode': modelCode,
      'productionDate': productionDate.toIso8601String(),
      'registrationModelYear': registrationModelYear,
      'engineCode': engineCode,
      'engineDescriptionAr': engineDescriptionAr,
      'transmissionCode': transmissionCode,
      'transmissionDescriptionAr': transmissionDescriptionAr,
      'finalDriveCode': finalDriveCode,
      'bodyStyleAr': bodyStyleAr,
      'exteriorColorCode': exteriorColorCode,
      'interiorColorCode': interiorColorCode,
      'driveSide': driveSide,
      'market': market,
      'sourceCatalogPath': sourceCatalogPath,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
