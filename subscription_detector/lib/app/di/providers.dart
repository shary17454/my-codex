import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../config/app_config.dart';

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar');

  void setLocale(Locale locale) {
    state = locale;
  }
}

final currencyControllerProvider =
    NotifierProvider<CurrencyController, SupportedCurrency>(
  CurrencyController.new,
);

class CurrencyController extends Notifier<SupportedCurrency> {
  @override
  SupportedCurrency build() => AppConfig.defaultCurrency;

  void setCurrency(SupportedCurrency currency) {
    state = currency;
  }
}
