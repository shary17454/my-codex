class NotificationRule {
  const NotificationRule({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;
}
