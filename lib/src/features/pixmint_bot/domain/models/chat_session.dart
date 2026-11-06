import 'bot_user_role.dart';
import 'chat_message.dart';

/// Represents a distinct conversation thread between a user and PIXMINT BOT.
class ChatSession {
  final String id;
  final String title;
  final BotUserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final bool isArchived;

  const ChatSession({
    required this.id,
    required this.title,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.isArchived = false,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    BotUserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    bool? isArchived,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'isArchived': isArchived,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String? ?? 'sess-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Conversation',
      role: BotUserRole.fromString(
          json['role'] as String? ?? json['userRole'] as String? ?? 'engineer'),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
              : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
              : DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      isArchived: json['isArchived'] as bool? ??
          (json['is_archived'] == 1 || json['is_archived'] == true),
    );
  }
}
