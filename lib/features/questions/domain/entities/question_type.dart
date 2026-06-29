enum QuestionType {
  twoOptions('two_options'),
  multipleOptions('multiple_options'),
  open('open');

  const QuestionType(this.id);

  final String id;
}
