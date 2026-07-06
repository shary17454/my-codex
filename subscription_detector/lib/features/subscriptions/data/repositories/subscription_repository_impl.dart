import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../services/subscription_detector.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl(this._detector);

  final SubscriptionDetector _detector;

  @override
  Future<List<Subscription>> detectSubscriptions(List<Transaction> transactions) async {
    return _detector.detect(transactions);
  }
}
