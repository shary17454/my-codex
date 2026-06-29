import '../../../transactions/domain/entities/transaction.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class DetectSubscriptions {
  const DetectSubscriptions(this._repository);

  final SubscriptionRepository _repository;

  Future<List<Subscription>> call(List<Transaction> transactions) {
    return _repository.detectSubscriptions(transactions);
  }
}
