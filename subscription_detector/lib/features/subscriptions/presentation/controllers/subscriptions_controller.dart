import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/controllers/transaction_import_controller.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../data/services/subscription_detector.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/usecases/detect_subscriptions.dart';

final subscriptionDetectorProvider = Provider((ref) => const SubscriptionDetector());

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepositoryImpl(ref.watch(subscriptionDetectorProvider)),
);

final detectSubscriptionsProvider = Provider(
  (ref) => DetectSubscriptions(ref.watch(subscriptionRepositoryProvider)),
);

final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final transactions = await ref.watch(transactionImportControllerProvider.future);
  return ref.watch(detectSubscriptionsProvider).call(transactions);
});
