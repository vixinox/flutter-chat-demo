import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';
import '../api_client.dart';
import '../models/model.dart';

enum LoadStatus { idle, loading, success, error }

class MessageProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<ChatMessage> _messages = [];
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  ChatMessage? _streamingMessage;

  Function(String)? onConversationIdCreated;

  MessageProvider({required this.apiClient});

  List<ChatMessage> get messages => _messages;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> updateAndLoadMessages(String? conversationId) async {

    if (conversationId == null || conversationId.isEmpty) {
      _messages = [];
      _status = LoadStatus.idle;
      _streamingMessage = null;
      notifyListeners();
      return;
    }

    _status = LoadStatus.loading;
    notifyListeners();

    try {
      final res = await apiClient.get('/messages/$conversationId');
      _messages = (res.data as List)
          .map((j) => ChatMessage.fromJson(j))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _status = LoadStatus.success;
    } catch (e) {
      _status = LoadStatus.error;
      _error = e.toString();
      _messages = [];
    }
    notifyListeners();
  }

  Future<String?> sendMessageAndGetReply({
    required String content,
    required Model model,
    required String? conversationId,
  }) async {
    if (content.trim().isEmpty) return null;
    if (model.name.trim().isEmpty) {
      _error = '模型名称为空，无法发送请求';
      notifyListeners();
      return null;
    }

    _error = null;
    notifyListeners();

    final tempUserMsg = ChatMessage(
      id: 'temp_user_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId ?? 'pending',
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(tempUserMsg);
    notifyListeners();

    String? responseConversationId;
    String? messageId;
    String? modelName = model.name;
    String? modelDisplayName = model.displayName;
    String? modelProvider = model.provider;
    String accumulatedContent = '';
    bool hasReceivedChunk = false;

    try {
      final requestData = {
        'model': model.name,
        'content': content,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
      };

      final baseUrl = apiClient.baseUrl;
      final url = Uri.parse('$baseUrl/chat');
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(requestData);

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode != 200) {
        throw Exception('请求失败: ${streamedResponse.statusCode}');
      }

      _messages.removeWhere((m) => m.id == tempUserMsg.id);
      final sentUserMsg = tempUserMsg.copyWith(status: MessageStatus.sent);
      _messages.add(sentUserMsg);

      _streamingMessage = ChatMessage(
        id: 'temp_assistant_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId ?? 'pending',
        role: MessageRole.assistant,
        content: '',
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
        modelName: modelName,
        modelDisplayName: modelDisplayName,
        modelProvider: modelProvider,
      );
      _messages.add(_streamingMessage!);
      notifyListeners();

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (var line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data.isEmpty || data == '[DONE]') continue;

          try {
            final json = jsonDecode(data);
            final type = json['type'];

            switch (type) {
              case 'init':
                responseConversationId = json['conversationId'];
                final serverModelName = json['modelName'];
                final serverModelDisplayName = json['modelDisplayName'];
                final serverModelProvider = json['modelProvider'];

                print('[MessageProvider] SSE init - conversationId: $responseConversationId');
                print('[MessageProvider] SSE init - model info: $serverModelName, $serverModelDisplayName, $serverModelProvider');

                if (serverModelName != null) modelName = serverModelName;
                if (serverModelDisplayName != null) modelDisplayName = serverModelDisplayName;
                if (serverModelProvider != null) modelProvider = serverModelProvider;

                if (responseConversationId != null && conversationId == null) {
                  print('[MessageProvider] New conversation created: $responseConversationId');
                  onConversationIdCreated?.call(responseConversationId);
                }

                final index = _messages.indexWhere((m) => m.id == _streamingMessage?.id);
                if (index != -1) {
                  _streamingMessage = _streamingMessage!.copyWith(
                    conversationId: responseConversationId ?? conversationId ?? 'pending',
                    modelName: modelName,
                    modelDisplayName: modelDisplayName,
                    modelProvider: modelProvider,
                  );
                  _messages[index] = _streamingMessage!;
                }
                break;

              case 'chunk':
                final delta = json['content'] as String?;
                if (delta != null && delta.isNotEmpty) {
                  hasReceivedChunk = true;
                  accumulatedContent += delta;
                  final index = _messages.indexWhere((m) => m.id == _streamingMessage?.id);
                  if (index != -1) {
                    _streamingMessage = _streamingMessage!.copyWith(content: accumulatedContent);
                    _messages[index] = _streamingMessage!;
                    notifyListeners();
                  }
                }
                break;

              case 'done':
                messageId = json['messageId'];
                final fullContent = json['fullContent'] as String?;
                final createdAt = json['createdAt'] as String?;

                print('[MessageProvider] SSE done - messageId: $messageId');

                final finalModelName = _streamingMessage?.modelName ?? modelName;
                final finalModelDisplayName = _streamingMessage?.modelDisplayName ?? modelDisplayName;
                final finalModelProvider = _streamingMessage?.modelProvider ?? modelProvider;

                _messages.removeWhere((m) => m.id == _streamingMessage?.id);
                final finalMessage = ChatMessage(
                  id: messageId ?? 'unknown',
                  conversationId: responseConversationId ?? conversationId ?? 'unknown',
                  role: MessageRole.assistant,
                  content: fullContent ?? accumulatedContent,
                  createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
                  status: MessageStatus.sent,
                  modelName: finalModelName,
                  modelDisplayName: finalModelDisplayName,
                  modelProvider: finalModelProvider,
                );
                _messages.add(finalMessage);
                _streamingMessage = null;

                print('[MessageProvider] Final message model info: $finalModelName, $finalModelDisplayName, $finalModelProvider');
                break;

              case 'error':
                final errorMsg = json['message'] as String?;
                throw Exception(errorMsg ?? '未知错误');
            }
          } catch (e) {
            print('[MessageProvider] SSE parse error: $e, data: $data');
          }
        }
      }
    } catch (e) {
      print('[MessageProvider] Send error: $e');
      _error = e.toString();
    } finally {
      if (_streamingMessage != null) {
        _messages.removeWhere((m) => m.id == _streamingMessage?.id);
        if (hasReceivedChunk) {
          final partialModelName = _streamingMessage?.modelName ?? modelName;
          final partialModelDisplayName = _streamingMessage?.modelDisplayName ?? modelDisplayName;
          final partialModelProvider = _streamingMessage?.modelProvider ?? modelProvider;

          final partialMessage = ChatMessage(
            id: messageId ?? 'temp_assistant_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: responseConversationId ?? conversationId ?? 'unknown',
            role: MessageRole.assistant,
            content: accumulatedContent,
            createdAt: DateTime.now(),
            status: MessageStatus.sent,
            modelName: partialModelName,
            modelDisplayName: partialModelDisplayName,
            modelProvider: partialModelProvider,
          );
          _messages.add(partialMessage);
        } else {
          final userMsgIndex = _messages.indexWhere((m) => m.id == tempUserMsg.id);
          if (userMsgIndex != -1) {
            _messages[userMsgIndex] = _messages[userMsgIndex].copyWith(status: MessageStatus.failed);
          } else {
            _messages.add(tempUserMsg.copyWith(status: MessageStatus.failed));
          }
          _error ??= '网络中断，未收到任何回复';
        }
        _streamingMessage = null;
      }

      if (responseConversationId != null) {
        final userMsgIndex = _messages.indexWhere((m) =>
        m.id == tempUserMsg.id || m.role == MessageRole.user && m.content == content
        );
        if (userMsgIndex != -1 && userMsgIndex < _messages.length) {
          _messages[userMsgIndex] = _messages[userMsgIndex].copyWith(
            conversationId: responseConversationId,
          );
        }
      }

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    }

    return responseConversationId ?? conversationId;
  }

  Future<void> refreshMessages(String? conversationId) async {
    await updateAndLoadMessages(conversationId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}