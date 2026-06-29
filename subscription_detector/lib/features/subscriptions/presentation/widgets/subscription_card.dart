import 'package:flutter/material.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_category.dart';
import '../../domain/entities/subscription_status.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    required this.subscription,
    required this.locale,
    super.key,
  });

  final Subscription subscription;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subscription.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _StatusChip(status: subscription.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_cadenceText(localizations, subscription.cadence))),
                Chip(label: Text(_categoryText(localizations, subscription.category))),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: localizations.text('amount'),
              value: CurrencyFormatter.format(
                subscription.amount,
                currency: subscription.currency,
                locale: locale,
              ),
            ),
            _InfoRow(
              label: localizations.text('nextCharge'),
              value: _date(subscription.nextChargeDate),
            ),
            _InfoRow(
              label: localizations.text('chargeCount'),
              value: subscription.chargeCount.toString(),
            ),
            _InfoRow(
              label: localizations.text('annualCost'),
              value: CurrencyFormatter.format(
                subscription.annualCost,
                currency: subscription.currency,
                locale: locale,
              ),
            ),
            _InfoRow(
              label: localizations.text('annualSavings'),
              value: CurrencyFormatter.format(
                subscription.potentialAnnualSavings,
                currency: subscription.currency,
                locale: locale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _cadenceText(AppLocalizations localizations, SubscriptionCadence cadence) {
    return switch (cadence) {
      SubscriptionCadence.monthly => localizations.text('monthly'),
      SubscriptionCadence.annual => localizations.text('annual'),
      SubscriptionCadence.recurring => localizations.text('recurring'),
    };
  }

  String _categoryText(AppLocalizations localizations, SubscriptionCategory category) {
    return switch (category) {
      SubscriptionCategory.digitalServices => localizations.text('digitalServices'),
      SubscriptionCategory.entertainment => localizations.text('entertainment'),
      SubscriptionCategory.apps => localizations.text('apps'),
      SubscriptionCategory.fitness => localizations.text('fitness'),
      SubscriptionCategory.other => localizations.text('other'),
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final color = switch (status) {
      SubscriptionStatus.likelyUsed => Colors.green,
      SubscriptionStatus.needsReview => Colors.orange,
      SubscriptionStatus.unnecessary => Colors.red,
    };
    final text = switch (status) {
      SubscriptionStatus.likelyUsed => localizations.text('likelyUsed'),
      SubscriptionStatus.needsReview => localizations.text('needsReview'),
      SubscriptionStatus.unnecessary => localizations.text('unnecessary'),
    };

    return Chip(
      label: Text(text),
      side: BorderSide(color: color.shade300),
      backgroundColor: color.shade50,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
