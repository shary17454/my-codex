import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../app/config/app_config.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/domain/entities/subscription_status.dart';
import '../../domain/entities/ai_insight.dart';
import 'ai_insights_datasource.dart';
import 'local_ai_insights_datasource.dart';

class OpenAiInsightsDataSource implements AiInsightsDataSource {
  OpenAiInsightsDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final LocalAiInsightsDataSource _fallback = const LocalAiInsightsDataSource();

  @override
  Future<AiInsight> generateInsights(List<Subscription> subscriptions) async {
    final fallback = await _fallback.generateInsights(subscriptions);
    if (AppConfig.openAiApiKey.isEmpty || subscriptions.isEmpty) {
      return fallback;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${AppConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': AppConfig.openAiModel,
        'temperature': 0.2,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a financial assistant. Return compact Arabic recommendations for reducing subscription spend. Do not request bank credentials.',
          },
          {
            'role': 'user',
            'content': jsonEncode({
              'subscriptions': subscriptions
                  .map(
                    (subscription) => {
                      'name': subscription.name,
                      'amount': subscription.amount,
                      'currency': subscription.currency.code,
                      'annualCost': subscription.annualCost,
                      'status': subscription.status.name,
                      'potentialAnnualSavings': subscription.potentialAnnualSavings,
                    },
                  )
                  .toList(),
            }),
          },
        ],
      },
    );

    final choices = response.data?['choices'] as List<dynamic>?;
    final firstChoice = choices == null || choices.isEmpty ? null : choices.first;
    final message = firstChoice is Map<String, dynamic>
        ? firstChoice['message'] as Map<String, dynamic>?
        : null;
    final summary = message?['content']?.toString().trim();

    if (summary == null || summary.isEmpty) {
      return fallback;
    }

    final candidates = subscriptions
        .where((subscription) => subscription.status != SubscriptionStatus.likelyUsed)
        .toList()
      ..sort((a, b) => b.potentialAnnualSavings.compareTo(a.potentialAnnualSavings));
    final topCandidates = candidates.take(3).toList();
    final annualSavings = topCandidates.fold<double>(
      0,
      (sum, subscription) => sum + subscription.potentialAnnualSavings,
    );

    return AiInsight(
      monthlySavings: annualSavings / 12,
      annualSavings: annualSavings,
      summary: summary,
      cancelCandidates: topCandidates,
      recommendations: const [
        'راجع الاشتراكات ذات الاستخدام غير الواضح قبل التجديد القادم.',
        'احتفظ بخدمة واحدة فقط لكل فئة ترفيهية عند تداخل الاستخدام.',
        'فعّل تذكيرًا شهريًا لمراجعة أي اشتراك جديد أو مرتفع التكلفة.',
      ],
    );
  }
}
