import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/screens/home_screen.dart';
import '../../../price_analysis/domain/entities/price_analysis_request.dart';
import '../../../price_analysis/domain/entities/price_analysis_result.dart';
import '../../../price_analysis/presentation/providers/price_analysis_providers.dart';
import '../../../search_history/domain/entities/search_history_item.dart';
import '../../../search_history/presentation/providers/search_history_providers.dart';
import '../../domain/entities/ocr_result.dart';

class OcrResultScreen extends ConsumerStatefulWidget {
  const OcrResultScreen({super.key, required this.result});

  static const routeName = 'ocr-result';
  static const routePath = '/ocr-result';

  final OcrResult? result;

  @override
  ConsumerState<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends ConsumerState<OcrResultScreen> {
  Future<PriceAnalysisResult>? _analysisFuture;

  @override
  void initState() {
    super.initState();
    final result = widget.result;
    if (result?.productName != null && result?.price != null) {
      _analysisFuture = _analyzeAndSave(result!);
    }
  }

  Future<PriceAnalysisResult> _analyzeAndSave(OcrResult ocrResult) async {
    final createdAt = DateTime.now();
    final analysis = await ref.read(analyzePriceUseCaseProvider)(
          PriceAnalysisRequest(
            productName: ocrResult.productName!,
            detectedPrice: ocrResult.price!,
          ),
        );

    await ref.read(searchHistoryRepositoryProvider).save(
          SearchHistoryItem(
            id: createdAt.microsecondsSinceEpoch.toString(),
            createdAt: createdAt,
            result: analysis,
          ),
        );

    ref.invalidate(searchHistoryItemsProvider);
    return analysis;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '\u0646\u062a\u064a\u062c\u0629 '
            '\u0627\u0644\u062a\u062d\u0644\u064a\u0644',
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final result = widget.result;
    final analysisFuture = _analysisFuture;

    if (result == null) {
      return _MessageState(
        message: '\u0644\u0627 \u062a\u0648\u062c\u062f '
            '\u0646\u062a\u064a\u062c\u0629 OCR',
        onBack: () => context.goNamed(HomeScreen.routeName),
      );
    }

    if (analysisFuture == null) {
      return _MessageState(
        message: '\u0644\u0645 \u064a\u062a\u0645 '
            '\u0627\u0633\u062a\u062e\u0631\u0627\u062c '
            '\u0627\u0633\u0645 \u0627\u0644\u0645\u0646\u062a\u062c '
            '\u0648\u0627\u0644\u0633\u0639\u0631',
        onBack: () => context.goNamed(HomeScreen.routeName),
      );
    }

    return FutureBuilder<PriceAnalysisResult>(
      future: analysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _MessageState(
            message: '\u0644\u0627 \u062a\u062a\u0648\u0641\u0631 '
                '\u0628\u064a\u0627\u0646\u0627\u062a \u0633\u0648\u0642 '
                '\u0644\u0647\u0630\u0627 \u0627\u0644\u0645\u0646\u062a\u062c',
            onBack: () => context.goNamed(HomeScreen.routeName),
          );
        }

        return _AnalysisContent(
          result: snapshot.data!,
          rawText: result.rawText,
        );
      },
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({
    required this.result,
    required this.rawText,
  });

  final PriceAnalysisResult result;
  final String rawText;

  @override
  Widget build(BuildContext context) {
    final market = result.marketSnapshot;

    return ListView(
      children: [
        _RecommendationBanner(result: result),
        const SizedBox(height: 16),
        _InfoRow(
          label: '\u0627\u0633\u0645 \u0627\u0644\u0645\u0646\u062a\u062c',
          value: result.productName,
        ),
        _InfoRow(
          label: '\u0627\u0644\u0633\u0639\u0631 '
              '\u0627\u0644\u0645\u0648\u062c\u0648\u062f',
          value: _formatPrice(result.detectedPrice),
        ),
        _InfoRow(
          label: '\u0645\u062a\u0648\u0633\u0637 '
              '\u0633\u0639\u0631 \u0627\u0644\u0633\u0648\u0642',
          value: _formatPrice(market.averagePrice),
        ),
        _InfoRow(
          label: '\u0623\u0642\u0644 \u0633\u0639\u0631 '
              '\u0645\u062a\u0627\u062d',
          value: _formatPrice(market.lowestPrice),
        ),
        _InfoRow(
          label: '\u0623\u0639\u0644\u0649 \u0633\u0639\u0631 '
              '\u0645\u062a\u0627\u062d',
          value: _formatPrice(market.highestPrice),
        ),
        _InfoRow(
          label: '\u0646\u0633\u0628\u0629 '
              '\u0627\u0644\u0641\u0631\u0642 \u0639\u0646 '
              '\u0627\u0644\u0633\u0648\u0642',
          value: '${result.differencePercent.toStringAsFixed(1)}%',
        ),
        _InfoRow(
          label: '\u062d\u0627\u0644\u0629 '
              '\u0627\u0644\u0633\u0639\u0631',
          value: _statusLabel(result.status),
        ),
        _InfoRow(
          label: '\u0647\u0644 \u0627\u0644\u062a\u062e\u0641\u064a\u0636 '
              '\u062d\u0642\u064a\u0642\u064a \u0623\u0645 '
              '\u0648\u0647\u0645\u064a',
          value: _discountLabel(result.isFakeDiscount),
        ),
        _InfoRow(
          label: '\u0627\u0644\u0645\u062a\u0627\u062c\u0631 '
              '\u0627\u0644\u0623\u0631\u062e\u0635',
          value: market.cheaperStores.isEmpty
              ? '-'
              : market.cheaperStores.join(', '),
        ),
        const SizedBox(height: 16),
        Text(
          '\u0627\u0644\u0646\u0635 '
          '\u0627\u0644\u0645\u0633\u062a\u062e\u0631\u062c',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SelectableText(rawText.isEmpty ? '-' : rawText),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.goNamed(HomeScreen.routeName),
          icon: const Icon(Icons.home_outlined),
          label: const Text(
            '\u0627\u0644\u0639\u0648\u062f\u0629 '
            '\u0644\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
          ),
        ),
      ],
    );
  }
}

class _RecommendationBanner extends StatelessWidget {
  const _RecommendationBanner({required this.result});

  final PriceAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u0627\u0644\u062a\u0648\u0635\u064a\u0629 '
              '\u0627\u0644\u0646\u0647\u0627\u0626\u064a\u0629',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _recommendationLabel(result.recommendation),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onBack,
            child: const Text(
              '\u0627\u0644\u0639\u0648\u062f\u0629',
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(double value) => value.toStringAsFixed(2);

String _statusLabel(PriceStatus status) {
  return switch (status) {
    PriceStatus.excellent => '\u0645\u0645\u062a\u0627\u0632',
    PriceStatus.fair => '\u0645\u0646\u0627\u0633\u0628',
    PriceStatus.high => '\u0645\u0631\u062a\u0641\u0639',
    PriceStatus.overpriced => '\u0645\u0628\u0627\u0644\u063a \u0641\u064a\u0647',
  };
}

String _recommendationLabel(PurchaseRecommendation recommendation) {
  return switch (recommendation) {
    PurchaseRecommendation.buyNow => '\u0627\u0634\u062a\u0631\u0650 \u0627\u0644\u0622\u0646',
    PurchaseRecommendation.wait => '\u0627\u0646\u062a\u0638\u0631',
    PurchaseRecommendation.doNotBuy => '\u0644\u0627 \u062a\u0634\u062a\u0631\u0650',
  };
}

String _discountLabel(bool? isFakeDiscount) {
  return switch (isFakeDiscount) {
    true => '\u0648\u0647\u0645\u064a',
    false => '\u062d\u0642\u064a\u0642\u064a',
    null => '\u063a\u064a\u0631 \u0645\u062a\u0648\u0641\u0631',
  };
}
