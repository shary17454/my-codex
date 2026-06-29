import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/theme/app_theme.dart';
import 'router/app_router.dart';

class PriceDetectorApp extends ConsumerWidget {
  const PriceDetectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '\u0643\u0627\u0634\u0641 \u0627\u0644\u0623\u0633\u0639\u0627\u0631',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
