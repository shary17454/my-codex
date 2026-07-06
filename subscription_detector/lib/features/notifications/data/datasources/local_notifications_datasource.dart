import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../../domain/entities/notification_rule.dart';
import 'notifications_datasource.dart';

class LocalNotificationsDataSource implements NotificationsDataSource {
  LocalNotificationsDataSource({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<String, NotificationRule> _rules = {};

  @override
  Future<void> schedule(NotificationRule rule) async {
    _rules[rule.id] = rule;

    if (rule.scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    try {
      await _plugin.zonedSchedule(
        id: rule.id.hashCode.abs(),
        title: rule.title,
        body: rule.body,
        scheduledDate: timezone.TZDateTime.from(rule.scheduledAt, timezone.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_reminders',
            'Subscription reminders',
            channelDescription: 'Reminders for upcoming subscription charges.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on Object {
      // Permissions and platform support vary; the rule remains visible in-app.
    }
  }

  @override
  Future<List<NotificationRule>> scheduledRules() async {
    return List.unmodifiable(_rules.values);
  }
}
