import 'bot_user_role.dart';

/// Predefined quick-action prompt suggestion for users based on their active role.
class ChatSuggestion {
  final String id;
  final String label;
  final String prompt;
  final BotUserRole role;
  final String? iconName;

  const ChatSuggestion({
    required this.id,
    required this.label,
    required this.prompt,
    required this.role,
    this.iconName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'prompt': prompt,
        'role': role.name,
        if (iconName != null) 'iconName': iconName,
      };

  factory ChatSuggestion.fromJson(Map<String, dynamic> json) {
    final rawLabel = (json['label'] ?? json['text'] ?? json['prompt'] ?? '') as String;
    final rawPrompt = (json['prompt'] ?? json['text'] ?? json['label'] ?? '') as String;
    final rawId = (json['id'] ?? 'sug_${rawPrompt.hashCode.abs()}') as String;
    return ChatSuggestion(
      id: rawId,
      label: rawLabel.isNotEmpty ? rawLabel : rawPrompt,
      prompt: rawPrompt.isNotEmpty ? rawPrompt : rawLabel,
      role: BotUserRole.fromString(json['role'] as String?),
      iconName: json['iconName'] as String?,
    );
  }
}
