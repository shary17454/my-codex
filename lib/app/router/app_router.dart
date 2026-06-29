import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/camera_scan/presentation/screens/camera_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/product_analysis/domain/entities/product_report.dart';
import '../../features/product_analysis/presentation/screens/product_report_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final isSignedIn = authState.hasValue && authState.value != null;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublicRoute = location == '/' || location == '/login';

      if (!isSignedIn && !isPublicRoute) {
        return '/login';
      }
      if (isSignedIn && isPublicRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/camera',
        name: RouteNames.camera,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/report',
        name: RouteNames.report,
        builder: (context, state) {
          return ProductReportScreen(report: state.extra as ProductReport?);
        },
      ),
    ],
  );
});
