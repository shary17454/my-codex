import '../../../subscriptions/domain/entities/subscription.dart';
import '../entities/notification_rule.dart';
import '../repositories/notifications_repository.dart';

class SchedulePaymentReminder {
  const SchedulePaymentReminder(this._repository);

  final NotificationsRepository _repository;

  Future<void> call(Subscription subscription) {
    final scheduledAt = subscription.nextChargeDate.subtract(const Duration(days: 2));
    return _repository.schedule(
      NotificationRule(
        id: 'payment-${subscription.id}',
        title: 'تذكير اشتراك',
        body: 'اقترب موعد خصم ${subscription.name}.',
        scheduledAt: scheduledAt,
      ),
    );
  }
}
