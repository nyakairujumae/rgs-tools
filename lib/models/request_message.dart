class RequestMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final String createdAt;
  final bool isSystem;

  RequestMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isSystem,
  });

  factory RequestMessage.fromMap(Map<String, dynamic> map) => RequestMessage(
        id: map['id'],
        threadId: map['thread_id'],
        senderId: map['sender_id'],
        text: map['text'] ?? '',
        createdAt: map['created_at'],
        isSystem: map['is_system'] == true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'thread_id': threadId,
        'sender_id': senderId,
        'text': text,
        'created_at': createdAt,
        'is_system': isSystem,
      };
}


