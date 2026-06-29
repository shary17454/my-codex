import 'package:ask_people/features/questions/presentation/controllers/mvp_demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedQuestionsPage extends ConsumerWidget {
  const SavedQuestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(mvpDemoControllerProvider).savedQuestions;

    return Scaffold(
      appBar: AppBar(title: const Text('الأسئلة المحفوظة')),
      body: questions.isEmpty
          ? const Center(child: Text('لا توجد أسئلة محفوظة أو مشارك فيها بعد'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final question = questions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(question.text),
                  subtitle: Text(
                    '${question.category.label} · ${question.votesCount} صوت · ${question.comments.length} تعليق',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/questions/${question.id}'),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: questions.length,
            ),
    );
  }
}
