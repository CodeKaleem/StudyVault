class ChatServer {
  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final String? description;
  final String? bannerUrl;
  final bool allowStudentMessages; // New: Chat permission setting

  ChatServer({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    this.description,
    this.bannerUrl,
    this.allowStudentMessages = true, // Default: everyone can chat
  });

  factory ChatServer.fromJson(Map<String, dynamic> json) {
    return ChatServer(
      id: json['id'],
      name: json['name'],
      inviteCode: json['invite_code'],
      ownerId: json['owner_id'],
      description: json['description'],
      bannerUrl: json['banner_url'],
      allowStudentMessages: json['allow_student_messages'] ?? true,
    );
  }
}
