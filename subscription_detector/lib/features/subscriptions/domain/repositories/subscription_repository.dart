import '../../../transactions/domain/entities/transaction.dart';
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> detectSubscriptions(List<Transaction> transactions);
}
