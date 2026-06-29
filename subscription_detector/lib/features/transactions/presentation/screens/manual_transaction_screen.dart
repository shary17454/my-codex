import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../domain/entities/transaction.dart';
import '../controllers/transaction_import_controller.dart';

class ManualTransactionScreen extends ConsumerStatefulWidget {
  const ManualTransactionScreen({super.key});

  @override
  ConsumerState<ManualTransactionScreen> createState() => _ManualTransactionScreenState();
}

class _ManualTransactionScreenState extends ConsumerState<ManualTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currency = ref.watch(currencyControllerProvider);
    final state = ref.watch(transactionImportControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.text('manualEntry'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _merchantController,
                            decoration: InputDecoration(
                              labelText: localizations.text('merchant'),
                              prefixIcon: const Icon(Icons.storefront_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: localizations.text('amount'),
                              prefixIcon: const Icon(Icons.payments_outlined),
                              suffixText: currency.code,
                            ),
                            validator: (value) {
                              if (_required(value) != null) {
                                return _required(value);
                              }
                              return double.tryParse(value!.trim()) == null
                                  ? localizations.text('requiredField')
                                  : null;
                            },
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              '${localizations.text('date')}: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: localizations.text('description'),
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: state.isLoading ? null : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(localizations.text('save')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).text('requiredField');
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currency = ref.read(currencyControllerProvider);
    await ref.read(transactionImportControllerProvider.notifier).addManual(
          Transaction(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            date: _date,
            merchant: _merchantController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
            currency: currency,
            description: _descriptionController.text.trim(),
          ),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).text('transactionSaved'))),
    );
    Navigator.of(context).pop();
  }
}
