import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class PoetsPage extends StatefulWidget {
  const PoetsPage({super.key});

  @override
  State<PoetsPage> createState() => _PoetsPageState();
}

class _PoetsPageState extends State<PoetsPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _poets = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPoets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPoets([String? query]) async {
    setState(() => _loading = true);
    try {
      final path = query != null && query.trim().isNotEmpty ? '/poets?q=${Uri.encodeQueryComponent(query.trim())}' : '/poets';
      final response = await ApiClient().get<List<dynamic>>(path);
      final data = response.data ?? [];
      _poets = data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      _poets = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشعراء')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onSubmitted: _loadPoets,
                decoration: InputDecoration(
                  hintText: 'ابحث عن شاعر',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () => _loadPoets(_searchController.text),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _poets.isEmpty && !_loading
                  ? const Center(child: Text('لا يوجد شعراء'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _poets.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final poet = _poets[index];
                        final name = poet['fullName']?.toString() ?? 'بدون اسم';
                        final bio = poet['bio']?.toString();
                        return ListTile(
                          leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: bio != null && bio.isNotEmpty ? Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
