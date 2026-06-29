import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';

final getDashboardSummaryProvider = Provider<GetDashboardSummary>(
  (ref) => const GetDashboardSummary(),
);

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final subscriptions = ref.watch(subscriptionsProvider);
  return subscriptions.whenData(ref.watch(getDashboardSummaryProvider).call);
});
