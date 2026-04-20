import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String role;

  @HiveField(2)
  final String content;

  // thinkingSteps 暂不直接存储为 HiveField，如需存储可后续扩展
  final Map<String, dynamic>? thinkingSteps;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.thinkingSteps,
  }) : id = id ?? const Uuid().v4();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      role: json['role'] as String,
      content: json['content'] as String,
      thinkingSteps: json['thinkingSteps'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      if (thinkingSteps != null) 'thinkingSteps': thinkingSteps,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}