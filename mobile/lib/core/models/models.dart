import '../api/api_client.dart';

/// Data models matching the backend contracts (server/app/schemas/contracts.py).

class Bot {
  final String id;
  final String name;
  final String role;
  final String description;
  final String avatar;
  final String model;
  final String accentColor;
  final String systemPrompt;
  final List<String> tools;
  final bool pinned;
  final String createdAt;

  Bot({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.avatar,
    required this.model,
    required this.accentColor,
    required this.systemPrompt,
    required this.tools,
    required this.pinned,
    required this.createdAt,
  });

  factory Bot.fromJson(Map<String, dynamic> json) => Bot(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String? ?? '',
        description: json['description'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '🤖',
        model: json['model'] as String? ?? 'gpt-5-mini',
        accentColor: json['accent_color'] as String? ?? 'cyan',
        systemPrompt: json['system_prompt'] as String? ?? '',
        tools: (json['tools'] as List<dynamic>?)?.cast<String>() ?? const [],
        pinned: json['pinned'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toCreateJson() => {
        'id': id,
        'name': name,
        'role': role,
        'description': description,
        'avatar': avatar,
        'model': model,
        'accent_color': accentColor,
        'system_prompt': systemPrompt,
        'tools': tools,
        'pinned': pinned,
      };
}

class Message {
  final String id;
  final String threadId;
  final String botId;
  final String sender;
  final String text;
  final String createdAt;
  final String? model;
  final String? itemType;
  final String? imageUrl;

  Message({
    required this.id,
    required this.threadId,
    required this.botId,
    required this.sender,
    required this.text,
    required this.createdAt,
    this.model,
    this.itemType,
    this.imageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        threadId: json['thread_id'] as String,
        botId: json['bot_id'] as String,
        sender: json['sender'] as String,
        text: json['text'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        model: json['model'] as String?,
        itemType: json['item_type'] as String?,
        imageUrl: json['image_url'] as String?,
      );
}

class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final String description;
  final bool recommended;
  final bool isAvailable;

  ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.recommended,
    required this.isAvailable,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String? ?? '',
        description: json['description'] as String? ?? '',
        recommended: json['recommended'] as bool? ?? false,
        isAvailable: json['is_available'] as bool? ?? true,
      );
}
