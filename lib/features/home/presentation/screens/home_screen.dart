import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../capture/presentation/screens/capture_screen.dart';
import '../../../search_history/presentation/screens/search_history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            IconButton(
              tooltip: '\u062a\u0633\u062c\u064a\u0644 '
                  '\u0627\u0644\u062e\u0631\u0648\u062c',
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '\u0627\u0644\u0635\u0641\u062d\u0629 '
                '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                '\u062c\u0627\u0647\u0632 \u0644\u0628\u062f\u0621 '
                '\u0628\u0646\u0627\u0621 MVP \u0639\u0644\u0649 '
                '\u0645\u0631\u0627\u062d\u0644.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.goNamed(CaptureScreen.routeName),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(
                  '\u062a\u0635\u0648\u064a\u0631 '
                  '\u0641\u0627\u062a\u0648\u0631\u0629 \u0623\u0648 '
                  '\u0645\u0646\u062a\u062c',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.goNamed(SearchHistoryScreen.routeName),
                icon: const Icon(Icons.history),
                label: const Text(
                  '\u0633\u062c\u0644 '
                  '\u0639\u0645\u0644\u064a\u0627\u062a '
                  '\u0627\u0644\u0628\u062d\u062b',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
