import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../subscriptions/presentation/widgets/subscription_card.dart';
import '../controllers/ai_insights_controller.dart';

class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final currency = ref.watch(currencyControllerProvider);
    final insightsState = ref.watch(aiInsightsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.text('aiInsights'))),
      body: SafeArea(
        child: insightsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (insight) {
            if (insight.cancelCandidates.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(localizations.text('noInsights')),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SavingsPanel(
                  monthly: CurrencyFormatter.format(
                    insight.monthlySavings,
                    currency: currency,
                    locale: locale.languageCode,
                  ),
                  annual: CurrencyFormatter.format(
                    insight.annualSavings,
                    currency: currency,
                    locale: locale.languageCode,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.text('smartSummary'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(insight.summary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.text('cancelCandidates'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...insight.cancelCandidates.map(
                  (subscription) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SubscriptionCard(
                      subscription: subscription,
                      locale: locale.languageCode,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.text('recommendations'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...insight.recommendations.map(
                  (recommendation) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(recommendation),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SavingsPanel extends StatelessWidget {
  const _SavingsPanel({
    required this.monthly,
    required this.annual,
  });

  final String monthly;
  final String annual;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SavingItem(
                label: localizations.text('monthlySavings'),
                value: monthly,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SavingItem(
                label: localizations.text('annualSavings'),
                value: annual,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingItem extends StatelessWidget {
  const _SavingItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
