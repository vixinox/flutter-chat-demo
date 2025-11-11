import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

enum MessageStatus {
  sending,
  sent,
  failed,
  received
}

enum MessageRole {
  user,
  assistant,
  system
}

@JsonSerializable()
class ChatMessage {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  final String? modelName;
  final String? modelDisplayName;
  final String? modelProvider;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.modelName,
    this.modelDisplayName,
    this.modelProvider,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

extension ChatMessageCopyWith on ChatMessage {
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    String? modelName,
    String? modelDisplayName,
    String? modelProvider,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      modelName: modelName ?? this.modelName,
      modelDisplayName: modelDisplayName ?? this.modelDisplayName,
      modelProvider: modelProvider ?? this.modelProvider,
    );
  }
}