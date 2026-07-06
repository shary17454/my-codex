import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as timezone;

class AppBootstrap {
  const AppBootstrap._();

  static const transactionsBoxName = 'transactions';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map<dynamic, dynamic>>(transactionsBoxName);
    timezone.initializeTimeZones();
    await _initializeNotifications();
    await _tryInitializeFirebase();
  }

  static Future<void> _initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      windows: WindowsInitializationSettings(
        appName: 'Subscription Detector',
        appUserModelId: 'com.cashif.subscriptions.subscription_detector',
        guid: '8E27E7B4-92D1-45A4-9B9B-2CBA919BF4D4',
      ),
    );

    await FlutterLocalNotificationsPlugin().initialize(settings: initializationSettings);
  }

  static Future<void> _tryInitializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } on Object {
      // Firebase is optional until firebase_options.dart and platform files are configured.
    }
  }
}
