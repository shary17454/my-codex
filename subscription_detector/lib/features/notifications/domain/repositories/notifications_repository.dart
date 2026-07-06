import '../entities/notification_rule.dart';

abstract class NotificationsRepository {
  Future<void> schedule(NotificationRule rule);

  Future<List<NotificationRule>> scheduledRules();
}
