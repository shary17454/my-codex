import '../../domain/entities/notification_rule.dart';

abstract class NotificationsDataSource {
  Future<void> schedule(NotificationRule rule);

  Future<List<NotificationRule>> scheduledRules();
}
