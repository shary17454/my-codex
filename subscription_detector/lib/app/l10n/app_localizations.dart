import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'ar': {
      'appName': 'كاشف الاشتراكات',
      'dashboardTitle': 'لوحة التحكم',
      'dashboardSubtitle': 'نظرة أولية على الاشتراكات والمصروفات المتكررة',
      'totalSubscriptions': 'إجمالي الاشتراكات',
      'monthlySpend': 'الإنفاق الشهري',
      'annualSpend': 'الإنفاق السنوي',
      'forgottenSubscriptions': 'اشتراكات تحتاج مراجعة',
      'potentialSavings': 'التوفير المحتمل',
      'importStatement': 'رفع كشف حساب',
      'manualEntry': 'إدخال عملية يدويًا',
      'language': 'اللغة',
      'currency': 'العملة',
      'arabic': 'العربية',
      'english': 'English',
      'sar': 'ريال سعودي',
      'usd': 'دولار أمريكي',
      'emptyState': 'ستظهر النتائج بعد رفع كشف حساب أو إدخال عمليات.',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'signInWithGoogle': 'الدخول باستخدام Google',
      'signInWithApple': 'الدخول باستخدام Apple',
      'logout': 'تسجيل الخروج',
      'authSubtitle': 'ادخل لاكتشاف الاشتراكات المتكررة وتحليل مصروفاتك.',
      'requiredField': 'هذا الحقل مطلوب',
      'invalidEmail': 'أدخل بريدًا إلكترونيًا صحيحًا',
      'importTitle': 'رفع كشف حساب',
      'importSubtitle': 'ارفع ملف PDF أو CSV لتحويل العمليات إلى بيانات قابلة للتحليل.',
      'pickPdf': 'اختيار PDF',
      'pickCsv': 'اختيار CSV',
      'importedTransactions': 'العمليات المستوردة',
      'noTransactions': 'لا توجد عمليات مستوردة بعد.',
      'merchant': 'اسم التاجر',
      'amount': 'المبلغ',
      'date': 'التاريخ',
      'category': 'التصنيف',
      'save': 'حفظ',
      'transactionSaved': 'تم حفظ العملية',
      'description': 'الوصف',
      'subscriptions': 'الاشتراكات',
      'viewSubscriptions': 'عرض الاشتراكات',
      'aiInsights': 'التوصيات الذكية',
      'nextCharge': 'الخصم القادم',
      'chargeCount': 'عدد مرات الخصم',
      'annualCost': 'التكلفة السنوية',
      'annualSavings': 'التوفير السنوي',
      'likelyUsed': 'مستخدم غالبًا',
      'needsReview': 'يحتاج مراجعة',
      'unnecessary': 'غير ضروري',
      'monthly': 'شهري',
      'annual': 'سنوي',
      'recurring': 'متكرر',
      'digitalServices': 'خدمات رقمية',
      'entertainment': 'ترفيه',
      'apps': 'تطبيقات',
      'fitness': 'لياقة',
      'other': 'أخرى',
      'noSubscriptions': 'لم يتم اكتشاف اشتراكات بعد.',
      'monthlySavings': 'التوفير الشهري',
      'smartSummary': 'ملخص مالي ذكي',
      'cancelCandidates': 'أهم الاشتراكات التي يمكن إلغاؤها',
      'recommendations': 'توصيات لتقليل المصروفات',
      'noInsights': 'لا توجد توصيات بعد. أضف عمليات متكررة أولًا.',
    },
    'en': {
      'appName': 'Subscription Detector',
      'dashboardTitle': 'Dashboard',
      'dashboardSubtitle': 'A first look at subscriptions and recurring spend',
      'totalSubscriptions': 'Total subscriptions',
      'monthlySpend': 'Monthly spend',
      'annualSpend': 'Annual spend',
      'forgottenSubscriptions': 'Needs review',
      'potentialSavings': 'Potential savings',
      'importStatement': 'Import statement',
      'manualEntry': 'Manual entry',
      'language': 'Language',
      'currency': 'Currency',
      'arabic': 'العربية',
      'english': 'English',
      'sar': 'Saudi Riyal',
      'usd': 'US Dollar',
      'emptyState': 'Results will appear after importing a statement or adding transactions.',
      'email': 'Email',
      'password': 'Password',
      'login': 'Sign in',
      'signInWithGoogle': 'Sign in with Google',
      'signInWithApple': 'Sign in with Apple',
      'logout': 'Sign out',
      'authSubtitle': 'Sign in to detect recurring subscriptions and analyze your spend.',
      'requiredField': 'This field is required',
      'invalidEmail': 'Enter a valid email address',
      'importTitle': 'Import statement',
      'importSubtitle': 'Upload a PDF or CSV file to convert statement rows into analyzable transactions.',
      'pickPdf': 'Pick PDF',
      'pickCsv': 'Pick CSV',
      'importedTransactions': 'Imported transactions',
      'noTransactions': 'No transactions imported yet.',
      'merchant': 'Merchant',
      'amount': 'Amount',
      'date': 'Date',
      'category': 'Category',
      'save': 'Save',
      'transactionSaved': 'Transaction saved',
      'description': 'Description',
      'subscriptions': 'Subscriptions',
      'viewSubscriptions': 'View subscriptions',
      'aiInsights': 'AI insights',
      'nextCharge': 'Next charge',
      'chargeCount': 'Charge count',
      'annualCost': 'Annual cost',
      'annualSavings': 'Annual savings',
      'likelyUsed': 'Likely used',
      'needsReview': 'Needs review',
      'unnecessary': 'Unnecessary',
      'monthly': 'Monthly',
      'annual': 'Annual',
      'recurring': 'Recurring',
      'digitalServices': 'Digital services',
      'entertainment': 'Entertainment',
      'apps': 'Apps',
      'fitness': 'Fitness',
      'other': 'Other',
      'noSubscriptions': 'No subscriptions detected yet.',
      'monthlySavings': 'Monthly savings',
      'smartSummary': 'Smart financial summary',
      'cancelCandidates': 'Top cancellation candidates',
      'recommendations': 'Recommendations to reduce spend',
      'noInsights': 'No insights yet. Add recurring transactions first.',
    },
  };

  String text(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((supportedLocale) => supportedLocale.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
