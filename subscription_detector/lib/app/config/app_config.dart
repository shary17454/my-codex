enum SupportedCurrency {
  sar('SAR', 'ر.س'),
  usd('USD', r'$');

  const SupportedCurrency(this.code, this.symbol);

  final String code;
  final String symbol;
}

class AppConfig {
  const AppConfig._();

  static const appNameAr = 'كاشف الاشتراكات';
  static const appNameEn = 'Subscription Detector';
  static const defaultCurrency = SupportedCurrency.sar;
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4.1-mini',
  );
}
