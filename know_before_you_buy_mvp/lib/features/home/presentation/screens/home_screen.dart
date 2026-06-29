import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../product_analysis/application/providers/product_analysis_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(productAnalysisControllerProvider.notifier).loadLatest(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final latestReportState = ref.watch(productAnalysisControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            onPressed: () => ref
                .read(authControllerProvider.notifier)
                .signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.homeSubtitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (latestReportState.hasValue &&
                      latestReportState.value != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(l10n.lastReport),
                        subtitle: Text(latestReportState.value!.productName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.goNamed(
                          RouteNames.report,
                          extra: latestReportState.value,
                        ),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.goNamed(RouteNames.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.scanProduct),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
