class RequestThread {
  final String id;
  final String toolId;
  final String ownerId;
  final String requesterId;
  final String status; // open, approved, closed
  final String createdAt;
  final String? lastMessageAt;

  RequestThread({
    required this.id,
    required this.toolId,
    required this.ownerId,
    required this.requesterId,
    required this.status,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory RequestThread.fromMap(Map<String, dynamic> map) => RequestThread(
        id: map['id'],
        toolId: map['tool_id'],
        ownerId: map['owner_id'],
        requesterId: map['requester_id'],
        status: map['status'],
        createdAt: map['created_at'],
        lastMessageAt: map['last_message_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'tool_id': toolId,
        'owner_id': ownerId,
        'requester_id': requesterId,
        'status': status,
        'created_at': createdAt,
        'last_message_at': lastMessageAt,
      };
}


