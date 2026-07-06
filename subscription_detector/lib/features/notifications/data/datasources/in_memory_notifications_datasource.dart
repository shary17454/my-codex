import '../../domain/entities/notification_rule.dart';
import 'notifications_datasource.dart';

class InMemoryNotificationsDataSource implements NotificationsDataSource {
  final Map<String, NotificationRule> _rules = {};

  @override
  Future<void> schedule(NotificationRule rule) async {
    _rules[rule.id] = rule;
  }

  @override
  Future<List<NotificationRule>> scheduledRules() async {
    return List.unmodifiable(_rules.values);
  }
}
