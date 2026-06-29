import 'package:ask_people/app/di/providers.dart';
import 'package:ask_people/app/router/route_names.dart';
import 'package:ask_people/features/auth/presentation/controllers/auth_providers.dart';
import 'package:ask_people/features/auth/presentation/pages/login_page.dart';
import 'package:ask_people/features/auth/presentation/pages/register_page.dart';
import 'package:ask_people/features/interests/presentation/pages/interests_page.dart';
import 'package:ask_people/features/onboarding/presentation/pages/start_page.dart';
import 'package:ask_people/features/questions/presentation/pages/create_question_page.dart';
import 'package:ask_people/features/questions/presentation/pages/home_page.dart';
import 'package:ask_people/features/questions/presentation/pages/question_details_page.dart';
import 'package:ask_people/features/saved_questions/presentation/pages/saved_questions_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseError = ref.watch(firebaseInitializationErrorProvider);
  final authState = firebaseError == null ? ref.watch(authStateProvider) : null;

  return GoRouter(
    initialLocation: '/start',
    redirect: (context, state) {
      final isStartRoute = state.matchedLocation == '/start';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (firebaseError != null) {
        return null;
      }

      final user = authState!.when(
        data: (user) => user,
        error: (error, stackTrace) => null,
        loading: () => null,
      );
      final isLoading = authState.isLoading;

      if (isLoading) {
        return null;
      }

      if (isStartRoute) {
        return null;
      }

      if (user == null && !isAuthRoute) {
        return '/login';
      }

      if (user != null && isAuthRoute) {
        return '/interests';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/start',
        name: RouteNames.start,
        builder: (context, state) => const StartPage(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/interests',
        name: RouteNames.interests,
        builder: (context, state) => const InterestsPage(),
      ),
      GoRoute(
        path: '/questions/new',
        name: RouteNames.createQuestion,
        builder: (context, state) => const CreateQuestionPage(),
      ),
      GoRoute(
        path: '/questions/:id',
        name: RouteNames.questionDetails,
        builder: (context, state) {
          return QuestionDetailsPage(questionId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/saved',
        name: RouteNames.savedQuestions,
        builder: (context, state) => const SavedQuestionsPage(),
      ),
    ],
  );
});
