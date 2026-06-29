import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/questions/domain/entities/question_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mvpDemoControllerProvider =
    NotifierProvider<MvpDemoController, MvpDemoState>(MvpDemoController.new);

class DemoQuestionOption {
  const DemoQuestionOption({
    required this.id,
    required this.text,
    required this.votesCount,
  });

  final String id;
  final String text;
  final int votesCount;

  DemoQuestionOption copyWith({int? votesCount}) {
    return DemoQuestionOption(
      id: id,
      text: text,
      votesCount: votesCount ?? this.votesCount,
    );
  }
}

class DemoComment {
  const DemoComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String text;
  final DateTime createdAt;
}

class DemoQuestion {
  const DemoQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.type,
    required this.options,
    required this.comments,
    required this.expiresAt,
    required this.createdAt,
    this.selectedOptionId,
    this.isFollowed = false,
    this.hasOpenAnswer = false,
  });

  final String id;
  final String text;
  final AppCategory category;
  final QuestionType type;
  final List<DemoQuestionOption> options;
  final List<DemoComment> comments;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? selectedOptionId;
  final bool isFollowed;
  final bool hasOpenAnswer;

  int get votesCount {
    return options.fold(0, (total, option) => total + option.votesCount);
  }

  int percentageFor(DemoQuestionOption option) {
    if (votesCount == 0) {
      return 0;
    }

    return ((option.votesCount / votesCount) * 100).round();
  }

  bool get isParticipated {
    return selectedOptionId != null || hasOpenAnswer || isFollowed;
  }

  DemoQuestion copyWith({
    List<DemoQuestionOption>? options,
    List<DemoComment>? comments,
    String? selectedOptionId,
    bool? isFollowed,
    bool? hasOpenAnswer,
  }) {
    return DemoQuestion(
      id: id,
      text: text,
      category: category,
      type: type,
      options: options ?? this.options,
      comments: comments ?? this.comments,
      expiresAt: expiresAt,
      createdAt: createdAt,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isFollowed: isFollowed ?? this.isFollowed,
      hasOpenAnswer: hasOpenAnswer ?? this.hasOpenAnswer,
    );
  }
}

class MvpDemoState {
  const MvpDemoState({
    required this.questions,
    required this.userInterests,
    this.selectedCategory,
    this.showOnlyInterests = true,
  });

  final List<DemoQuestion> questions;
  final Set<AppCategory> userInterests;
  final AppCategory? selectedCategory;
  final bool showOnlyInterests;

  List<DemoQuestion> get filteredQuestions {
    return questions.where((question) {
      final matchesCategory =
          selectedCategory == null || question.category == selectedCategory;
      final matchesInterest =
          !showOnlyInterests || userInterests.contains(question.category);

      return matchesCategory && matchesInterest;
    }).toList();
  }

  List<DemoQuestion> get savedQuestions {
    return questions.where((question) => question.isParticipated).toList();
  }

  MvpDemoState copyWith({
    List<DemoQuestion>? questions,
    Set<AppCategory>? userInterests,
    AppCategory? selectedCategory,
    bool clearSelectedCategory = false,
    bool? showOnlyInterests,
  }) {
    return MvpDemoState(
      questions: questions ?? this.questions,
      userInterests: userInterests ?? this.userInterests,
      selectedCategory:
          clearSelectedCategory ? null : selectedCategory ?? this.selectedCategory,
      showOnlyInterests: showOnlyInterests ?? this.showOnlyInterests,
    );
  }
}

class MvpDemoController extends Notifier<MvpDemoState> {
  @override
  MvpDemoState build() {
    final now = DateTime.now();

    return MvpDemoState(
      userInterests: const {
        AppCategory.cars,
        AppCategory.phones,
        AppCategory.restaurants,
        AppCategory.technology,
      },
      questions: [
        DemoQuestion(
          id: 'q1',
          text: 'أشتري السيارة A أو السيارة B؟',
          category: AppCategory.cars,
          type: QuestionType.twoOptions,
          options: const [
            DemoQuestionOption(id: 'a', text: 'السيارة A', votesCount: 18),
            DemoQuestionOption(id: 'b', text: 'السيارة B', votesCount: 11),
          ],
          comments: [
            DemoComment(
              id: 'c1',
              authorName: 'مستخدم',
              text: 'اختر السيارة A إذا كان استهلاك الوقود مهمًا لك.',
              createdAt: now.subtract(const Duration(hours: 2)),
            ),
          ],
          expiresAt: now.add(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        DemoQuestion(
          id: 'q2',
          text: 'أي مطعم تنصحون للعشاء العائلي؟',
          category: AppCategory.restaurants,
          type: QuestionType.multipleOptions,
          options: const [
            DemoQuestionOption(id: 'a', text: 'مطعم A', votesCount: 9),
            DemoQuestionOption(id: 'b', text: 'مطعم B', votesCount: 14),
            DemoQuestionOption(id: 'c', text: 'مطعم C', votesCount: 6),
          ],
          comments: [],
          expiresAt: now.add(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        DemoQuestion(
          id: 'q3',
          text: 'هل هذا المنتج يستحق الشراء؟',
          category: AppCategory.shopping,
          type: QuestionType.open,
          options: const [],
          comments: [
            DemoComment(
              id: 'c2',
              authorName: 'سارة',
              text: 'يستحق إذا كان السعر عليه تخفيض واضح.',
              createdAt: now.subtract(const Duration(minutes: 50)),
            ),
          ],
          expiresAt: now.add(const Duration(hours: 18)),
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ],
    );
  }

  void toggleInterestFilter(bool value) {
    state = state.copyWith(showOnlyInterests: value);
  }

  void selectCategory(AppCategory? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearSelectedCategory: category == null,
    );
  }

  void setUserInterests(Set<AppCategory> interests) {
    state = state.copyWith(userInterests: interests);
  }

  DemoQuestion? questionById(String id) {
    for (final question in state.questions) {
      if (question.id == id) {
        return question;
      }
    }

    return null;
  }

  void createQuestion({
    required String text,
    required AppCategory category,
    required QuestionType type,
    required List<String> optionTexts,
  }) {
    final now = DateTime.now();
    final id = 'q${now.microsecondsSinceEpoch}';
    final options = optionTexts
        .where((option) => option.trim().isNotEmpty)
        .map(
          (option) => DemoQuestionOption(
            id: '${option.hashCode}',
            text: option.trim(),
            votesCount: 0,
          ),
        )
        .toList();

    state = state.copyWith(
      questions: [
        DemoQuestion(
          id: id,
          text: text.trim(),
          category: category,
          type: type,
          options: options,
          comments: const [],
          expiresAt: now.add(const Duration(days: 3)),
          createdAt: now,
        ),
        ...state.questions,
      ],
    );
  }

  void vote(String questionId, String optionId) {
    state = state.copyWith(
      questions: [
        for (final question in state.questions)
          if (question.id == questionId)
            question.copyWith(
              selectedOptionId: optionId,
              options: [
                for (final option in question.options)
                  option.id == optionId && question.selectedOptionId == null
                      ? option.copyWith(votesCount: option.votesCount + 1)
                      : option,
              ],
            )
          else
            question,
      ],
    );
  }

  void addComment(String questionId, String text) {
    if (text.trim().isEmpty) {
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(
      questions: [
        for (final question in state.questions)
          if (question.id == questionId)
            question.copyWith(
              hasOpenAnswer: question.type == QuestionType.open
                  ? true
                  : question.hasOpenAnswer,
              comments: [
                DemoComment(
                  id: 'c${now.microsecondsSinceEpoch}',
                  authorName: 'أنت',
                  text: text.trim(),
                  createdAt: now,
                ),
                ...question.comments,
              ],
            )
          else
            question,
      ],
    );
  }

  void toggleFollow(String questionId) {
    state = state.copyWith(
      questions: [
        for (final question in state.questions)
          question.id == questionId
              ? question.copyWith(isFollowed: !question.isFollowed)
              : question,
      ],
    );
  }
}
