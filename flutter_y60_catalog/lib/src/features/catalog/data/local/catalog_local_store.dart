import '../../domain/models/catalog_models.dart';

abstract class CatalogLocalStore {
  Future<VehicleProfile?> readVehicleProfile(String id);

  Future<List<CatalogSection>> readSections();

  Future<List<CatalogPage>> readPagesBySection(String sectionId);

  Future<List<PartDiagram>> readDiagramsByPage(String catalogPageId);

  Future<List<PartItem>> readPartsByDiagram(String diagramId);

  Future<List<MaintenanceReminder>> readMaintenanceReminders(
    String vehicleProfileId,
  );

  Future<List<CommonIssue>> readCommonIssues(String vehicleProfileId);

  Future<void> upsertVehicleProfile(VehicleProfile profile);

  Future<void> upsertSections(List<CatalogSection> sections);

  Future<void> upsertPages(List<CatalogPage> pages);

  Future<void> upsertDiagrams(List<PartDiagram> diagrams);

  Future<void> upsertParts(List<PartItem> parts);
}
