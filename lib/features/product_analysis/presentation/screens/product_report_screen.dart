import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/utils/responsive.dart';
import '../../application/providers/product_analysis_provider.dart';
import '../../domain/entities/product_report.dart';

class ProductReportScreen extends ConsumerStatefulWidget {
  const ProductReportScreen({super.key, this.report});

  final ProductReport? report;

  @override
  ConsumerState<ProductReportScreen> createState() => _ProductReportScreenState();
}

class _ProductReportScreenState extends ConsumerState<ProductReportScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.report == null) {
      Future.microtask(
        () => ref.read(productAnalysisControllerProvider.notifier).loadLatest(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(productAnalysisControllerProvider);
    final report = widget.report ?? (state.hasValue ? state.value : null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: state.isLoading && report == null
                ? const Center(child: CircularProgressIndicator())
                : report == null
                ? Center(child: Text(l10n.reportPlaceholder))
                : _ReportContent(report: report),
          ),
        ),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report});

  final ProductReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(
              File(report.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.productName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: report.finalScore.clamp(0, 100) / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 12),
                Text('${l10n.finalScore}: ${report.finalScore} / 100'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _MetricCard(title: l10n.price, value: report.estimatedPrice),
        _MetricCard(
          title: l10n.fairPrice,
          value: report.isPriceFair ? 'نعم' : 'لا',
        ),
        _MetricCard(title: l10n.marketAverage, value: report.marketAveragePrice),
        _MetricCard(
          title: l10n.cheaperAlternative,
          value: report.cheaperAlternative,
        ),
        _MetricCard(
          title: l10n.userRating,
          value: report.userRating.toStringAsFixed(1),
        ),
        if (report.databaseSource != null)
          _MetricCard(title: l10n.databaseSource, value: report.databaseSource!),
        if (report.brand != null)
          _MetricCard(title: l10n.brand, value: report.brand!),
        if (report.healthGrade != null)
          _MetricCard(title: l10n.healthGrade, value: report.healthGrade!),
        if (report.categories != null)
          _MetricCard(title: l10n.categories, value: report.categories!),
        _MetricCard(
          title: l10n.recommendation,
          value: report.isWorthBuying ? 'نعم' : 'لا',
        ),
        _ListCard(title: l10n.pros, items: report.pros),
        _ListCard(title: l10n.cons, items: report.cons),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.circle, size: 6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
