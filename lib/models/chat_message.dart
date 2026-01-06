class ChatMessage {
  final String id;
  final String serverId;
  final String senderId;
  final String? messageText;
  final DateTime createdAt;
  
  // Decoupled Asset (Option A)
  final String? attachmentId;
  final Map<String, dynamic>? attachmentData; // Joined data: { title, file_url, file_type }
  
  // Sender Profile Data
  final Map<String, dynamic>? senderData; // Joined profile: { full_name, email, role }

  ChatMessage({
    required this.id,
    required this.serverId,
    required this.senderId,
    this.messageText,
    required this.createdAt,
    this.attachmentId,
    this.attachmentData,
    this.senderData,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      serverId: json['server_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      attachmentId: json['attachment_id'],
      attachmentData: json['content_library'], // Accessing the joined table
      senderData: json['profiles'], // Accessing joined sender profile
    );
  }
}
