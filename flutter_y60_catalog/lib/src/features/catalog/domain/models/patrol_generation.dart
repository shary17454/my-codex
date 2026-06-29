import 'vehicle_profile.dart';

class PatrolGeneration {
  const PatrolGeneration({
    required this.code,
    required this.nameAr,
    required this.years,
    required this.engines,
    required this.imageAssetPath,
    required this.imageDescriptionAr,
    this.vehicleProfile,
  });

  final String code;
  final String nameAr;
  final String years;
  final List<String> engines;
  final String imageAssetPath;
  final String imageDescriptionAr;
  final VehicleProfile? vehicleProfile;

  String get searchableText => [
        code,
        nameAr,
        years,
        imageDescriptionAr,
        ...engines,
        vehicleProfile?.searchableText,
      ].whereType<String>().join(' ');
}
