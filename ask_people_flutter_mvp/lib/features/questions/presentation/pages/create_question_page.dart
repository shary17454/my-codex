import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/questions/domain/entities/question_type.dart';
import 'package:ask_people/features/questions/presentation/controllers/mvp_demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateQuestionPage extends ConsumerStatefulWidget {
  const CreateQuestionPage({super.key});

  @override
  ConsumerState<CreateQuestionPage> createState() => _CreateQuestionPageState();
}

class _CreateQuestionPageState extends ConsumerState<CreateQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  AppCategory _category = AppCategory.cars;
  QuestionType _type = QuestionType.twoOptions;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsOptions = _type != QuestionType.open;
    final visibleOptions = _type == QuestionType.twoOptions ? 2 : 3;

    return Scaffold(
      appBar: AppBar(title: const Text('سؤال جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _questionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'أدخل نص السؤال';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'التصنيف'),
              items: [
                for (final category in AppCategory.values)
                  DropdownMenuItem(value: category, child: Text(category.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<QuestionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'نوع السؤال'),
              items: const [
                DropdownMenuItem(
                  value: QuestionType.twoOptions,
                  child: Text('اختيار بين خيارين'),
                ),
                DropdownMenuItem(
                  value: QuestionType.multipleOptions,
                  child: Text('اختيار من عدة خيارات'),
                ),
                DropdownMenuItem(
                  value: QuestionType.open,
                  child: Text('سؤال مفتوح'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            if (needsOptions) ...[
              const SizedBox(height: 16),
              for (var index = 0; index < visibleOptions; index++) ...[
                TextFormField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(labelText: 'الخيار ${index + 1}'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل الخيار';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submit,
              child: const Text('نشر السؤال'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(mvpDemoControllerProvider.notifier).createQuestion(
          text: _questionController.text,
          category: _category,
          type: _type,
          optionTexts: _type == QuestionType.open
              ? const []
              : _optionControllers.map((controller) => controller.text).toList(),
        );

    context.go('/home');
  }
}
