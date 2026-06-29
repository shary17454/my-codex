import '../entities/notification_rule.dart';
import '../repositories/notifications_repository.dart';

class ScheduleMonthlyReviewReminder {
  const ScheduleMonthlyReviewReminder(this._repository);

  final NotificationsRepository _repository;

  Future<void> call() {
    final now = DateTime.now();
    return _repository.schedule(
      NotificationRule(
        id: 'monthly-review',
        title: 'مراجعة الاشتراكات',
        body: 'راجع اشتراكاتك الشهرية وتأكد من الخدمات غير الضرورية.',
        scheduledAt: DateTime(now.year, now.month + 1, 1, 9),
      ),
    );
  }
}
