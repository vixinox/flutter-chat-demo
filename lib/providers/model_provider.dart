import 'package:flutter/material.dart';
import '../models/model.dart';
import '../api_client.dart';
import 'conversation_provider.dart';

class ModelProvider extends ChangeNotifier {
  final ApiClient apiClient;

  ModelProvider({required this.apiClient});

  List<Model> _models = [];
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  String? _selectedModelName;
  bool _hasLoaded = false;

  List<Model> get models => _models;
  LoadStatus get status => _status;
  String? get error => _error;
  String? get selectedModelName => _selectedModelName;
  Model? get selectedModel {
    if (_selectedModelName == null) return null;
    final matches = _models.where((m) => m.name == _selectedModelName);
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Future<void> loadModels({bool force = false}) async {
    if (_hasLoaded && !force) return;
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final res = await apiClient.get('/models');
      _models = (res.data as List).map((j) => Model.fromJson(j)).toList();
      if (_selectedModelName == null && _models.isNotEmpty) {
        _selectedModelName = _models.first.name;
      }
      _status = LoadStatus.success;
      _hasLoaded = true;
    } catch (e) {
      _status = LoadStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void selectModel(String? name) {
    _selectedModelName = name;
    notifyListeners();
  }
}