class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
}
