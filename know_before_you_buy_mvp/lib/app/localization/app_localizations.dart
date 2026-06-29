import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _values = {
    'en': {
      'appName': 'Know Before You Buy',
      'welcomeTitle': 'Know before you buy',
      'welcomeSubtitle': 'Scan a product and get a clear AI-powered buying report.',
      'getStarted': 'Get started',
      'previewApp': 'Preview app',
      'loginTitle': 'Sign in',
      'loginSubtitle': 'Choose the sign-in method you want to use.',
      'google': 'Continue with Google',
      'apple': 'Continue with Apple',
      'email': 'Continue with email',
      'emailAddress': 'Email address',
      'password': 'Password',
      'signIn': 'Sign in',
      'signOut': 'Sign out',
      'skipForNow': 'Skip for MVP preview',
      'homeTitle': 'Home',
      'homeSubtitle': 'Start by scanning a product.',
      'scanProduct': 'Scan product',
      'cameraTitle': 'Camera',
      'cameraPlaceholder': 'Camera integration will be implemented in phase 3.',
      'captureProduct': 'Capture product',
      'analyzing': 'Analyzing product...',
      'noCamera': 'No camera was found on this device.',
      'lastReport': 'Latest report',
      'reportTitle': 'Product report',
      'reportPlaceholder': 'AI product analysis will be implemented in phase 4.',
      'finalScore': 'Final score',
      'price': 'Estimated price',
      'marketAverage': 'Market average',
      'recommendation': 'Worth buying?',
      'fairPrice': 'Fair price',
      'cheaperAlternative': 'Cheaper alternative',
      'userRating': 'User rating',
      'databaseSource': 'Database source',
      'brand': 'Brand',
      'healthGrade': 'Health grade',
      'categories': 'Categories',
      'pros': 'Pros',
      'cons': 'Cons',
    },
    'ar': {
      'appName': 'اعرف قبل تشتري',
      'welcomeTitle': 'اعرف قبل تشتري',
      'welcomeSubtitle': 'صوّر أي منتج واحصل على تقرير شراء واضح مدعوم بالذكاء الاصطناعي.',
      'getStarted': 'ابدأ الآن',
      'previewApp': 'معاينة التطبيق',
      'loginTitle': 'تسجيل الدخول',
      'loginSubtitle': 'اختر طريقة تسجيل الدخول المناسبة لك.',
      'google': 'المتابعة باستخدام Google',
      'apple': 'المتابعة باستخدام Apple',
      'email': 'المتابعة بالبريد الإلكتروني',
      'emailAddress': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'signIn': 'تسجيل الدخول',
      'signOut': 'تسجيل الخروج',
      'skipForNow': 'تخطي لمعاينة MVP',
      'homeTitle': 'الرئيسية',
      'homeSubtitle': 'ابدأ بتصوير المنتج.',
      'scanProduct': 'تصوير منتج',
      'cameraTitle': 'الكاميرا',
      'cameraPlaceholder': 'سيتم تنفيذ ربط الكاميرا في المرحلة الثالثة.',
      'captureProduct': 'التقاط المنتج',
      'analyzing': 'جاري تحليل المنتج...',
      'noCamera': 'لم يتم العثور على كاميرا في هذا الجهاز.',
      'lastReport': 'آخر تقرير',
      'reportTitle': 'تقرير المنتج',
      'reportPlaceholder': 'سيتم تنفيذ تحليل الذكاء الاصطناعي في المرحلة الرابعة.',
      'finalScore': 'الدرجة النهائية',
      'price': 'السعر التقريبي',
      'marketAverage': 'متوسط السوق',
      'recommendation': 'هل يستحق الشراء؟',
      'fairPrice': 'السعر مناسب',
      'cheaperAlternative': 'بديل أرخص',
      'userRating': 'تقييم المستخدمين',
      'databaseSource': 'مصدر البيانات',
      'brand': 'العلامة التجارية',
      'healthGrade': 'التقييم الغذائي',
      'categories': 'التصنيفات',
      'pros': 'أبرز المميزات',
      'cons': 'أبرز العيوب',
    },
  };

  String get appName => _text('appName');
  String get welcomeTitle => _text('welcomeTitle');
  String get welcomeSubtitle => _text('welcomeSubtitle');
  String get getStarted => _text('getStarted');
  String get previewApp => _text('previewApp');
  String get loginTitle => _text('loginTitle');
  String get loginSubtitle => _text('loginSubtitle');
  String get google => _text('google');
  String get apple => _text('apple');
  String get email => _text('email');
  String get emailAddress => _text('emailAddress');
  String get password => _text('password');
  String get signIn => _text('signIn');
  String get signOut => _text('signOut');
  String get skipForNow => _text('skipForNow');
  String get homeTitle => _text('homeTitle');
  String get homeSubtitle => _text('homeSubtitle');
  String get scanProduct => _text('scanProduct');
  String get cameraTitle => _text('cameraTitle');
  String get cameraPlaceholder => _text('cameraPlaceholder');
  String get captureProduct => _text('captureProduct');
  String get analyzing => _text('analyzing');
  String get noCamera => _text('noCamera');
  String get lastReport => _text('lastReport');
  String get reportTitle => _text('reportTitle');
  String get reportPlaceholder => _text('reportPlaceholder');
  String get finalScore => _text('finalScore');
  String get price => _text('price');
  String get marketAverage => _text('marketAverage');
  String get recommendation => _text('recommendation');
  String get fairPrice => _text('fairPrice');
  String get cheaperAlternative => _text('cheaperAlternative');
  String get userRating => _text('userRating');
  String get databaseSource => _text('databaseSource');
  String get brand => _text('brand');
  String get healthGrade => _text('healthGrade');
  String get categories => _text('categories');
  String get pros => _text('pros');
  String get cons => _text('cons');

  String _text(String key) {
    return _values[locale.languageCode]?[key] ?? _values['en']![key]!;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
