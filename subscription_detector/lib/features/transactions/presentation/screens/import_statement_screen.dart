import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/transaction_import_controller.dart';

class ImportStatementScreen extends ConsumerWidget {
  const ImportStatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final state = ref.watch(transactionImportControllerProvider);
    final controller = ref.read(transactionImportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.text('importTitle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              localizations.text('importSubtitle'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.isLoading ? null : controller.pickAndImportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(localizations.text('pickPdf')),
                ),
                OutlinedButton.icon(
                  onPressed: state.isLoading ? null : controller.pickAndImportCsv,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(localizations.text('pickCsv')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              localizations.text('importedTransactions'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(localizations.text('noTransactions')),
                    ),
                  );
                }

                return Column(
                  children: transactions
                      .map(
                        (transaction) => Card(
                          child: ListTile(
                            title: Text(transaction.merchant),
                            subtitle: Text(
                              '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}',
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(
                                transaction.amount,
                                currency: transaction.currency,
                                locale: locale.languageCode,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
