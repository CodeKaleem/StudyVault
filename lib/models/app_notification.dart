class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      isRead: json['is_read'] ?? false,
      relatedEntityType: json['related_entity_type'],
      relatedEntityId: json['related_entity_id'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
