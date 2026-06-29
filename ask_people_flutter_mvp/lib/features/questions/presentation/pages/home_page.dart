import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/questions/presentation/controllers/mvp_demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mvpDemoControllerProvider);
    final controller = ref.read(mvpDemoControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اسأل الناس'),
        actions: [
          IconButton(
            tooltip: 'المحفوظة',
            onPressed: () => context.push('/saved'),
            icon: const Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('فلترة حسب اهتماماتي'),
            value: state.showOnlyInterests,
            onChanged: controller.toggleInterestFilter,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('الكل'),
                selected: state.selectedCategory == null,
                onSelected: (_) => controller.selectCategory(null),
              ),
              for (final category in AppCategory.values)
                FilterChip(
                  label: Text(category.label),
                  selected: state.selectedCategory == category,
                  onSelected: (_) => controller.selectCategory(category),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('الأسئلة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (state.filteredQuestions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('لا توجد أسئلة مطابقة للفلتر الحالي')),
            )
          else
            for (final question in state.filteredQuestions) ...[
              _QuestionCard(question: question),
              const SizedBox(height: 12),
            ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/questions/new'),
        tooltip: 'سؤال جديد',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final DemoQuestion question;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/questions/${question.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(label: Text(question.category.label)),
              const SizedBox(height: 8),
              Text(question.text, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(
                '${question.votesCount} صوت · ${question.comments.length} تعليق',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
