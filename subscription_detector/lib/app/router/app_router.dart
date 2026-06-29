import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/ai_insights/presentation/screens/ai_insights_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_result_screen.dart';
import '../../features/transactions/presentation/screens/import_statement_screen.dart';
import '../../features/transactions/presentation/screens/manual_transaction_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final isAuthenticated = authState.hasValue && authState.value != null;

  return GoRouter(
    initialLocation: isAuthenticated ? RouteNames.dashboard : RouteNames.login,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == RouteNames.login;

      if (!isAuthenticated && !isLoggingIn) {
        return RouteNames.login;
      }

      if (isAuthenticated && isLoggingIn) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: RouteNames.dashboardName,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.importStatement,
        name: RouteNames.importStatementName,
        builder: (context, state) => const ImportStatementScreen(),
      ),
      GoRoute(
        path: RouteNames.manualTransaction,
        name: RouteNames.manualTransactionName,
        builder: (context, state) => const ManualTransactionScreen(),
      ),
      GoRoute(
        path: RouteNames.subscriptions,
        name: RouteNames.subscriptionsName,
        builder: (context, state) => const SubscriptionsResultScreen(),
      ),
      GoRoute(
        path: RouteNames.aiInsights,
        name: RouteNames.aiInsightsName,
        builder: (context, state) => const AiInsightsScreen(),
      ),
    ],
  );
});
