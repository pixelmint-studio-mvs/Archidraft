import 'dart:convert';

/// Sender identity for messages within a chat session.
enum MessageSender {
  user,
  bot,
  system,
}

/// Delivery status of a message.
enum MessageStatus {
  sending,
  sent,
  error,
}

/// A citation or source reference accompanying a response.
class ChatSource {
  final String title;
  final String? docRef;
  final String? snippet;

  const ChatSource({
    required this.title,
    this.docRef,
    this.snippet,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (docRef != null) 'docRef': docRef,
        if (snippet != null) 'snippet': snippet,
      };

  factory ChatSource.fromJson(Map<String, dynamic> json) => ChatSource(
        title: json['title'] as String? ?? 'Documentation',
        docRef: json['docRef'] as String?,
        snippet: json['snippet'] as String?,
      );
}

/// Represents an individual chat message in a conversation.
class ChatMessage {
  final String id;
  final String sessionId;
  final MessageSender sender;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final List<ChatSource> sources;
  final String? errorMessage;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.sources = const [],
    this.errorMessage,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isBot => sender == MessageSender.bot;
  bool get isSystem => sender == MessageSender.system;
  bool get hasError => status == MessageStatus.error;

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageSender? sender,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    List<ChatSource>? sources,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sources: sources ?? this.sources,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'sender': sender.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'sources': sources.map((s) => s.toJson()).toList(),
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawSender = json['sender'] as String? ?? 'bot';
    MessageSender sender;
    if (rawSender == 'user') {
      sender = MessageSender.user;
    } else if (rawSender == 'system') {
      sender = MessageSender.system;
    } else {
      sender = MessageSender.bot;
    }

    final rawStatus = json['status'] as String? ?? 'sent';
    MessageStatus status;
    if (rawStatus == 'sending') {
      status = MessageStatus.sending;
    } else if (rawStatus == 'error') {
      status = MessageStatus.error;
    } else {
      status = MessageStatus.sent;
    }

    List<ChatSource> sources = const [];
    if (json['sources'] is List) {
      sources = (json['sources'] as List<dynamic>)
          .map((s) => ChatSource.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (json['sources_json'] is String) {
      try {
        final decoded = jsonDecode(json['sources_json'] as String) as List<dynamic>;
        sources = decoded
            .map((s) => ChatSource.fromJson(s as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    DateTime createdAt;
    if (json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int);
    } else if (json['created_at'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int);
    } else if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      id: json['id'] as String? ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: json['sessionId'] as String? ?? json['session_id'] as String? ?? '',
      sender: sender,
      content: json['content'] as String? ?? '',
      createdAt: createdAt,
      status: status,
      sources: sources,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
