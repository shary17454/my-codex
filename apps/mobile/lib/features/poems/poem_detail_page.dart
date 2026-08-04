import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class PoemDetailPage extends StatefulWidget {
  const PoemDetailPage({super.key, required this.poemId});

  final String poemId;

  @override
  State<PoemDetailPage> createState() => _PoemDetailPageState();
}

class _PoemDetailPageState extends State<PoemDetailPage> {
  late final Future<Map<String, dynamic>?> _poem = _loadPoem();

  Future<Map<String, dynamic>?> _loadPoem() async {
    try {
      final response = await ApiClient().get<Map<String, dynamic>>('/poems/${widget.poemId}');
      return response.data;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل القصيدة')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _poem,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final poem = snapshot.data;
            if (poem == null) {
              return const Center(child: Text('تعذّر تحميل القصيدة'));
            }
            final title = poem['title']?.toString() ?? 'بدون عنوان';
            final body = poem['body']?.toString() ?? '';
            final summary = poem['summary']?.toString();
            final verification = poem['verificationLevel']?.toString();
            final poetName = (poem['poet'] as Map?)?['fullName']?.toString();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (poetName != null) ...[
                  const SizedBox(height: 8),
                  Text('الشاعر: $poetName', style: const TextStyle(color: Colors.brown)),
                ],
                if (verification != null) ...[
                  const SizedBox(height: 4),
                  Text('درجة التحقق: $verification', style: const TextStyle(fontSize: 13)),
                ],
                if (summary != null && summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(summary, style: const TextStyle(fontSize: 15, height: 1.6)),
                ],
                const SizedBox(height: 20),
                Text(
                  body,
                  style: const TextStyle(fontSize: 18, height: 2.0),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
