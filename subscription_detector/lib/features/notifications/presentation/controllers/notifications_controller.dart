import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../data/datasources/local_notifications_datasource.dart';
import '../../data/datasources/notifications_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/notification_rule.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/schedule_monthly_review_reminder.dart';
import '../../domain/usecases/schedule_payment_reminder.dart';

final notificationsDataSourceProvider = Provider<NotificationsDataSource>(
  (ref) => LocalNotificationsDataSource(),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(ref.watch(notificationsDataSourceProvider)),
);

final schedulePaymentReminderProvider = Provider(
  (ref) => SchedulePaymentReminder(ref.watch(notificationsRepositoryProvider)),
);

final scheduleMonthlyReviewReminderProvider = Provider(
  (ref) => ScheduleMonthlyReviewReminder(ref.watch(notificationsRepositoryProvider)),
);

final notificationRulesProvider = FutureProvider<List<NotificationRule>>((ref) async {
  final subscriptions = await ref.watch(subscriptionsProvider.future);
  for (final subscription in subscriptions) {
    await ref.read(schedulePaymentReminderProvider).call(subscription);
  }
  await ref.read(scheduleMonthlyReviewReminderProvider).call();
  return ref.read(notificationsRepositoryProvider).scheduledRules();
});
