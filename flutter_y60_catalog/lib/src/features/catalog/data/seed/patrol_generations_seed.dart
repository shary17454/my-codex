import '../../domain/models/patrol_generation.dart';
import 'y60_vehicle_profile_seed.dart';

final patrolGenerationsSeed = [
  PatrolGeneration(
    code: 'Y60',
    nameAr: 'نيسان باترول Y60',
    years: '1987 - 1997',
    engines: const ['TB42', 'TB42S', 'TD42', 'RD28'],
    imageAssetPath: 'assets/generations/patrol_y60.jpg',
    imageDescriptionAr: 'نيسان باترول Y60 واجن، الجيل الرابع المناسب لكتالوج سفاري.',
    vehicleProfile: y60VehicleProfileSeed,
  ),
  PatrolGeneration(
    code: 'Y61',
    nameAr: 'نيسان باترول Y61',
    years: '1997 - 2023',
    engines: const ['TB45', 'TB48', 'TD42', 'ZD30'],
    imageAssetPath: 'assets/generations/patrol_y61.jpg',
    imageDescriptionAr: 'نيسان باترول Y61 واجن، الجيل الخامس من الباترول.',
  ),
  PatrolGeneration(
    code: 'Y62',
    nameAr: 'نيسان باترول Y62',
    years: '2010 - 2024',
    engines: const ['VK56VD', 'VK56DE'],
    imageAssetPath: 'assets/generations/patrol_y62.jpg',
    imageDescriptionAr: 'نيسان باترول Y62 واجن، الجيل السادس بمحركات VK56.',
  ),
  PatrolGeneration(
    code: 'Y63',
    nameAr: 'نيسان باترول Y63',
    years: '2025+',
    engines: const ['V6 Twin Turbo', 'V6'],
    imageAssetPath: 'assets/generations/patrol_y63.jpg',
    imageDescriptionAr: 'نيسان باترول Y63، الجيل الأحدث من الباترول.',
  ),
];
