import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';

class PoemsPage extends StatefulWidget {
  const PoemsPage({super.key});

  @override
  State<PoemsPage> createState() => _PoemsPageState();
}

class _PoemsPageState extends State<PoemsPage> {
  late final Future<List<Map<String, dynamic>>> _poems = _loadPoems();

  Future<List<Map<String, dynamic>>> _loadPoems() async {
    try {
      final response = await ApiClient().get<List<dynamic>>('/poems');
      final data = response.data ?? [];
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القصائد')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _poems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final poems = snapshot.data ?? [];
            if (poems.isEmpty) {
              return const Center(child: Text('لا توجد قصائد منشورة حالياً'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: poems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final poem = poems[index];
                final title = poem['title']?.toString() ?? 'بدون عنوان';
                final poetName = (poem['poet'] as Map?)?['fullName']?.toString();
                final id = poem['id']?.toString();
                return ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: poetName != null ? Text('الشاعر: $poetName') : null,
                  trailing: const Icon(Icons.chevron_left),
                  onTap: id != null ? () => context.push('/poems/$id') : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
