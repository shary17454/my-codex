import 'package:ask_people/app/ask_people_app.dart';
import 'package:ask_people/app/di/providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseInitializationError;
  try {
    await Firebase.initializeApp();
  } catch (error) {
    firebaseInitializationError = error;
  }

  await Hive.initFlutter();

  runApp(
    ProviderScope(
      overrides: [
        firebaseInitializationErrorProvider.overrideWithValue(
          firebaseInitializationError,
        ),
      ],
      child: const AskPeopleApp(),
    ),
  );
}
