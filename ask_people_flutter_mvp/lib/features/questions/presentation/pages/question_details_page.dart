import 'package:ask_people/features/questions/domain/entities/question_type.dart';
import 'package:ask_people/features/questions/presentation/controllers/mvp_demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionDetailsPage extends ConsumerStatefulWidget {
  const QuestionDetailsPage({
    required this.questionId,
    super.key,
  });

  final String questionId;

  @override
  ConsumerState<QuestionDetailsPage> createState() => _QuestionDetailsPageState();
}

class _QuestionDetailsPageState extends ConsumerState<QuestionDetailsPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = ref
        .watch(mvpDemoControllerProvider)
        .questions
        .where((item) => item.id == widget.questionId)
        .firstOrNull;

    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل السؤال')),
        body: const Center(child: Text('السؤال غير موجود')),
      );
    }

    final controller = ref.read(mvpDemoControllerProvider.notifier);
    final remaining = question.expiresAt.difference(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل السؤال'),
        actions: [
          IconButton(
            tooltip: 'مشاركة السؤال',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: question.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ نص السؤال للمشاركة')),
              );
            },
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: 'متابعة السؤال',
            onPressed: () => controller.toggleFollow(question.id),
            icon: Icon(
              question.isFollowed ? Icons.bookmark : Icons.bookmark_border,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Chip(label: Text(question.category.label)),
          const SizedBox(height: 8),
          Text(question.text, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '${question.votesCount} صوت · ينتهي خلال ${remaining.inHours.clamp(0, 999)} ساعة',
          ),
          const SizedBox(height: 20),
          if (question.type == QuestionType.open)
            const Text('هذا سؤال مفتوح. شارك رأيك في التعليقات.')
          else
            for (final option in question.options) ...[
              _VoteOption(question: question, option: option),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 24),
          Text('التعليقات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'اكتب تعليقك'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              controller.addComment(question.id, _commentController.text);
              _commentController.clear();
            },
            child: const Text('إضافة تعليق'),
          ),
          const SizedBox(height: 14),
          if (question.comments.isEmpty)
            const Text('لا توجد تعليقات بعد')
          else
            for (final comment in question.comments) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(comment.authorName),
                subtitle: Text(comment.text),
              ),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _VoteOption extends ConsumerWidget {
  const _VoteOption({
    required this.question,
    required this.option,
  });

  final DemoQuestion question;
  final DemoQuestionOption option;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = question.percentageFor(option);
    final isSelected = question.selectedOptionId == option.id;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: question.selectedOptionId == null
          ? () {
              ref
                  .read(mvpDemoControllerProvider.notifier)
                  .vote(question.id, option.id);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(option.text)),
                Text('$percentage%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: percentage / 100),
          ],
        ),
      ),
    );
  }
}
