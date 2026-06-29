import 'package:ask_people/app/di/providers.dart';
import 'package:ask_people/core/constants/app_interests.dart';
import 'package:ask_people/features/interests/presentation/controllers/interests_providers.dart';
import 'package:ask_people/features/questions/presentation/controllers/mvp_demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InterestsPage extends ConsumerWidget {
  const InterestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interestsControllerProvider);
    final isDemoMode = ref.watch(firebaseInitializationErrorProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الاهتمامات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isDemoMode) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('سيتم حفظ الاهتمامات محليًا لهذه التجربة.'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final interest in AppInterests.values)
                FilterChip(
                  label: Text(interest.label),
                  selected: state.selected.contains(interest),
                  onSelected: (_) {
                    ref
                        .read(interestsControllerProvider.notifier)
                        .toggle(interest);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.saveState.isLoading
                ? null
                : () async {
                    if (state.selected.isEmpty) {
                      return;
                    }

                    if (isDemoMode) {
                      ref
                          .read(mvpDemoControllerProvider.notifier)
                          .setUserInterests(state.selected);
                      context.go('/home');
                      return;
                    }

                    final success = await ref
                        .read(interestsControllerProvider.notifier)
                        .save();

                    if (success && context.mounted) {
                      context.go('/home');
                    }
                  },
            child: state.saveState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ الاهتمامات'),
          ),
          if (state.selected.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'اختر اهتمامًا واحدًا على الأقل.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          if (state.saveState.hasError && !isDemoMode) ...[
            const SizedBox(height: 12),
            Text(
              'تعذر حفظ الاهتمامات. حاول مرة أخرى.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
