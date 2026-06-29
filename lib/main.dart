import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app/app.dart';
import 'core/storage/local_storage.dart';
import 'features/product_analysis/application/providers/product_analysis_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = await LocalStorage.init();
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } on Object {
    // Firebase platform config is added after creating the Firebase project.
  }
  runApp(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(localStorage)],
      child: const KnowBeforeYouBuyApp(),
    ),
  );
}
