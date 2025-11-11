import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../api_client.dart';

enum LoadStatus { idle, loading, success, error }

class ConversationProvider extends ChangeNotifier {
  final ApiClient apiClient;

  ConversationProvider({required this.apiClient});

  List<Conversation> _conversations = [];
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  String? _selectedConversationId;
  bool _hasLoaded = false;

  List<Conversation> get conversations => _conversations;
  LoadStatus get status => _status;
  String? get error => _error;
  String? get selectedConversationId => _selectedConversationId;
  bool get hasLoaded => _hasLoaded;

  Conversation? get selectedConversation {
    if (_selectedConversationId == null) return null;
    final matches = _conversations.where((c) => c.id == _selectedConversationId);
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Future<void> loadConversations({bool force = false}) async {
    if (_hasLoaded && !force) {
      return;
    }
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final res = await apiClient.get('/conversations');
      _conversations = (res.data as List)
          .map((json) => Conversation.fromJson(json))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _status = LoadStatus.success;
      _hasLoaded = true;
    } catch (e) {
      _status = LoadStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void startNewConversation() {
    _selectedConversationId = null;
    notifyListeners();
  }

  void setConversationId(String id) {
    _selectedConversationId = id;

    if (!_conversations.any((c) => c.id == id)) {
      loadConversations(force: true);
    }
    notifyListeners();
  }

  void selectConversation(String? id) {
    _selectedConversationId = id;
    notifyListeners();
  }

  Future<bool> deleteConversation(String id) async {
    final backup = List<Conversation>.from(_conversations);
    _conversations.removeWhere((c) => c.id == id);
    if (_selectedConversationId == id) {
      _selectedConversationId = null;
    }
    notifyListeners();
    try {
      await apiClient.delete('/conversations/$id');
      return true;
    } catch (e) {
      _conversations = backup;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateConversationTitle(String id, String newTitle) async {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    final old = _conversations[idx];
    _conversations[idx] = old.copyWith(title: newTitle);
    notifyListeners();
    try {
      await apiClient.patch('/conversations/$id', data: {'title': newTitle});
      return true;
    } catch (e) {
      _conversations[idx] = old;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    _status = LoadStatus.loading;
    notifyListeners();

    try {
      final res = await apiClient.get('/conversations');
      _conversations = (res.data as List)
          .map((json) => Conversation.fromJson(json))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _status = LoadStatus.success;
      _hasLoaded = true;
    } catch (e) {
      _status = LoadStatus.error;
      _error = e.toString();
    }

    notifyListeners();
  }
}