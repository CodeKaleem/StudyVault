class Announcement {
  final String id;
  final String serverId;
  final String authorId;
  final String title;
  final String content;
  final bool isImportant;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined data
  final Map<String, dynamic>? authorData; // Profile of the author

  Announcement({
    required this.id,
    required this.serverId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.createdAt,
    required this.updatedAt,
    this.authorData,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      serverId: json['server_id'],
      authorId: json['author_id'],
      title: json['title'],
      content: json['content'],
      isImportant: json['is_important'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      authorData: json['profiles'], // Joined author profile
    );
  }
}
