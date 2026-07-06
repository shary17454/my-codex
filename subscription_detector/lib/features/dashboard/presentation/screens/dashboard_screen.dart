import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final currency = ref.watch(currencyControllerProvider);
    final summaryState = ref.watch(dashboardSummaryProvider);
    ref.watch(notificationRulesProvider);

    String money(num amount) => CurrencyFormatter.format(
          amount,
          currency: currency,
          locale: locale.languageCode,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.text('appName')),
        actions: [
          _LanguageMenu(locale: locale),
          _CurrencyMenu(currency: currency),
          IconButton(
            tooltip: localizations.text('logout'),
            onPressed: ref.read(authControllerProvider.notifier).signOut,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              localizations.text('dashboardTitle'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.text('dashboardSubtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            summaryState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (summary) => LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return GridView.count(
                    crossAxisCount: isWide ? 3 : 2,
                    childAspectRatio: isWide ? 1.7 : 1.15,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      MetricCard(
                        title: localizations.text('totalSubscriptions'),
                        value: summary.totalSubscriptions.toString(),
                      ),
                      MetricCard(
                        title: localizations.text('monthlySpend'),
                        value: money(summary.monthlySpend),
                      ),
                      MetricCard(
                        title: localizations.text('annualSpend'),
                        value: money(summary.annualSpend),
                      ),
                      MetricCard(
                        title: localizations.text('forgottenSubscriptions'),
                        value: summary.forgottenSubscriptions.toString(),
                      ),
                      MetricCard(
                        title: localizations.text('potentialSavings'),
                        value: money(summary.potentialSavings),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(localizations.text('emptyState')),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push(RouteNames.importStatement),
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(localizations.text('importStatement')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(RouteNames.manualTransaction),
                          icon: const Icon(Icons.add_card_outlined),
                          label: Text(localizations.text('manualEntry')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(RouteNames.subscriptions),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: Text(localizations.text('viewSubscriptions')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(RouteNames.aiInsights),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text(localizations.text('aiInsights')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageMenu extends ConsumerWidget {
  const _LanguageMenu({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return PopupMenuButton<Locale>(
      tooltip: localizations.text('language'),
      icon: const Icon(Icons.language),
      initialValue: locale,
      onSelected: ref.read(localeControllerProvider.notifier).setLocale,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: const Locale('ar'),
          child: Text(localizations.text('arabic')),
        ),
        PopupMenuItem(
          value: const Locale('en'),
          child: Text(localizations.text('english')),
        ),
      ],
    );
  }
}

class _CurrencyMenu extends ConsumerWidget {
  const _CurrencyMenu({required this.currency});

  final SupportedCurrency currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return PopupMenuButton<SupportedCurrency>(
      tooltip: localizations.text('currency'),
      icon: const Icon(Icons.payments_outlined),
      initialValue: currency,
      onSelected: ref.read(currencyControllerProvider.notifier).setCurrency,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SupportedCurrency.sar,
          child: Text(localizations.text('sar')),
        ),
        PopupMenuItem(
          value: SupportedCurrency.usd,
          child: Text(localizations.text('usd')),
        ),
      ],
    );
  }
}
