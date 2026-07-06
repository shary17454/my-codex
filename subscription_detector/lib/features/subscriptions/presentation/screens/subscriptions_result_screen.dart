import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../controllers/subscriptions_controller.dart';
import '../widgets/subscription_card.dart';

class SubscriptionsResultScreen extends ConsumerWidget {
  const SubscriptionsResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final subscriptionsState = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.text('subscriptions'))),
      body: SafeArea(
        child: subscriptionsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (subscriptions) {
            if (subscriptions.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(localizations.text('noSubscriptions')),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) => SubscriptionCard(
                subscription: subscriptions[index],
                locale: locale.languageCode,
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: subscriptions.length,
            );
          },
        ),
      ),
    );
  }
}
