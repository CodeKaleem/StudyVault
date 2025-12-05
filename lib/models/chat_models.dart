class ChatRoom {
  final String id;
  final String name;
  final String createdBy; // Teacher ID
  final List<String> participants; // User IDs
  final List<ChatMessage> messages;
  final List<SharedContent> sharedContent;

  ChatRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.participants,
    this.messages = const [],
    this.sharedContent = const [],
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });
}

class SharedContent {
  final String id;
  final String title;
  final String url; // or description
  final String type; // 'file', 'link'

  SharedContent({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
  });
}
