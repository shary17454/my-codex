import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/capture/presentation/screens/capture_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/ocr/domain/entities/ocr_result.dart';
import '../../features/ocr/presentation/screens/ocr_result_screen.dart';
import '../../features/search_history/presentation/screens/search_history_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isLoggedIn = authState.asData?.value != null;

  return GoRouter(
    initialLocation: LoginScreen.routePath,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == LoginScreen.routePath;

      if (!isLoggedIn && !isLoggingIn) {
        return LoginScreen.routePath;
      }

      if (isLoggedIn && isLoggingIn) {
        return HomeScreen.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: CaptureScreen.routePath,
        name: CaptureScreen.routeName,
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: OcrResultScreen.routePath,
        name: OcrResultScreen.routeName,
        builder: (context, state) {
          return OcrResultScreen(result: state.extra as OcrResult?);
        },
      ),
      GoRoute(
        path: SearchHistoryScreen.routePath,
        name: SearchHistoryScreen.routeName,
        builder: (context, state) => const SearchHistoryScreen(),
      ),
    ],
  );
});
