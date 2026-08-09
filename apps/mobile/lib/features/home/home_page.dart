import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_session.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final Future<List<String>> _sections = _loadSections();

  Future<List<String>> _loadSections() async {
    try {
      final response = await ApiClient().get<Map<String, dynamic>>('/home');
      final items = response.data?['featuredSections'];
      if (items is List) return items.map((item) => item.toString()).toList();
    } catch (_) {
      return const ['الشعر', 'الشعراء', 'القصص', 'الكتب والمراجع', 'الخيل', 'الإبل', 'الصقارة'];
    }
    return const ['الشعر', 'القصص', 'الكتب والمراجع'];
  }

  String _sectionRoute(String section) {
    if (section.contains('شعراء') || section.contains('شاعر')) return '/poets';
    if (section.contains('قصائد') || section.contains('شعر')) return '/poems';
    if (section.contains('قصص')) return '/stories';
    if (section.contains('كتب') || section.contains('مراجع')) return '/books';
    if (section.contains('خيل')) return '/horses';
    if (section.contains('إبل') || section.contains('ابل')) return '/camels';
    if (section.contains('صقور') || section.contains('صقارة') || section.contains('صيد')) return '/hunting';
    if (section.contains('كلاب')) return '/hunting-dogs';
    if (section.contains('مفضل')) return '/favorites';
    if (section.contains('سؤال') || section.contains('أسئل')) return '/questions';
    return '/search';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);
    final accountLabel = auth.isAuthenticated
        ? (auth.user?.displayName?.isNotEmpty == true ? auth.user!.displayName! : 'حسابي')
        : 'دخول';

    return Scaffold(
      appBar: AppBar(
        title: const Text('رواية'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/auth'),
            icon: Icon(auth.isAuthenticated ? Icons.person : Icons.login),
            label: Text(accountLabel),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'رواية… ذاكرة التراث العربي',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              onTap: () => context.go('/search'),
              decoration: const InputDecoration(
                hintText: 'ابحث في الشعر والقصص والمراجع',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<String>>(
              future: _sections,
              builder: (context, snapshot) {
                final sections = snapshot.data ?? const ['الشعر', 'القصص', 'الكتب'];
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: sections
                      .map(
                        (section) => ActionChip(
                          label: Text(section),
                          onPressed: () => context.go(_sectionRoute(section)),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
