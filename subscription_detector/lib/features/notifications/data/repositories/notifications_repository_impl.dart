import '../../domain/entities/notification_rule.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dataSource);

  final NotificationsDataSource _dataSource;

  @override
  Future<void> schedule(NotificationRule rule) {
    return _dataSource.schedule(rule);
  }

  @override
  Future<List<NotificationRule>> scheduledRules() {
    return _dataSource.scheduledRules();
  }
}
