enum MaintenanceReminderIntervalUnit {
  day,
  month,
  kilometer,
}

class MaintenanceReminder {
  const MaintenanceReminder({
    required this.id,
    required this.vehicleProfileId,
    required this.titleAr,
    required this.relatedPartItemIds,
    required this.intervalValue,
    required this.intervalUnit,
    required this.isEnabled,
    required this.updatedAt,
    this.descriptionAr,
    this.lastCompletedAt,
    this.lastCompletedOdometerKm,
  });

  final String id;
  final String vehicleProfileId;
  final String titleAr;
  final String? descriptionAr;
  final List<String> relatedPartItemIds;
  final int intervalValue;
  final MaintenanceReminderIntervalUnit intervalUnit;
  final bool isEnabled;
  final DateTime? lastCompletedAt;
  final int? lastCompletedOdometerKm;
  final DateTime updatedAt;

  String get searchableText => [
        titleAr,
        descriptionAr,
      ].whereType<String>().join(' ');

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) {
    return MaintenanceReminder(
      id: json['id'] as String,
      vehicleProfileId: json['vehicleProfileId'] as String,
      titleAr: json['titleAr'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      relatedPartItemIds: List<String>.from(json['relatedPartItemIds'] as List),
      intervalValue: json['intervalValue'] as int,
      intervalUnit: MaintenanceReminderIntervalUnit.values.byName(
        json['intervalUnit'] as String,
      ),
      isEnabled: json['isEnabled'] as bool,
      lastCompletedAt: json['lastCompletedAt'] == null
          ? null
          : DateTime.parse(json['lastCompletedAt'] as String),
      lastCompletedOdometerKm: json['lastCompletedOdometerKm'] as int?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleProfileId': vehicleProfileId,
      'titleAr': titleAr,
      'descriptionAr': descriptionAr,
      'relatedPartItemIds': relatedPartItemIds,
      'intervalValue': intervalValue,
      'intervalUnit': intervalUnit.name,
      'isEnabled': isEnabled,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'lastCompletedOdometerKm': lastCompletedOdometerKm,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
