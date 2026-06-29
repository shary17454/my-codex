# Flutter Y60 Catalog Foundation

This folder contains the initial architecture and data model foundation for a Flutter mobile app for Nissan Patrol Safari catalog content.

Scope is intentionally limited to:

- Dart data models
- Offline-first storage contracts
- Arabic-first / RTL-ready naming fields
- Catalog PDF, page image, and diagram references
- Search-ready text fields for future full-text indexing
- Seed vehicle profile data
- A minimal `main.dart` shell that reads from the seed/domain layer

No authentication, backend integration, or package installations are included.

## Suggested Folder Structure

```text
flutter_y60_catalog/
  pubspec.yaml
  assets/
    catalog/
      pages/
      diagrams/
  lib/
    main.dart
    src/
      features/
        catalog/
          domain/
            models/
              vehicle_profile.dart
              catalog_section.dart
              catalog_page.dart
              part_diagram.dart
              part_item.dart
              maintenance_reminder.dart
              common_issue.dart
              patrol_generation.dart
              catalog_models.dart
          data/
            local/
              catalog_local_store.dart
            seed/
              y60_vehicle_profile_seed.dart
              patrol_generations_seed.dart
```

## Architecture Notes

The catalog module is structured around offline-first content. The app should load the Nissan Patrol Safari catalog PDF, rendered page images, diagram images, and extracted metadata into a local store before building search workflows.

Each main entity includes stable IDs and JSON serialization methods. Search is prepared through `searchableText` getters, but no search engine or database package is added yet.

Images and diagrams are referenced by local asset paths:

- `CatalogPage.pageImagePath` points to a rendered catalog page image.
- `PartDiagram.imagePath` points to a cropped or extracted diagram image.
- `PartItem.imagePath` is optional for future direct part photos.

## Seed Data

The seed files define:

- Nissan Patrol Safari Y60 SGL
- WGY60 chassis prefix
- TB42S engine
- Manual 5 Speed
- FS5R50A transmission
- Gulf / Saudi market
- Patrol generations Y60, Y61, Y62, and Y63 for the initial app shell
