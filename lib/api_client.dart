import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  final Dio _dio;
  String get baseUrl => _dio.options.baseUrl;

  ApiClient(String baseUrl)
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  )) {
    final adapter = IOHttpClientAdapter();
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.findProxy = (uri) {
        return "PROXY 10.0.2.2:10810";
      };
      return client;
    };
    _dio.httpClientAdapter = adapter;
  }

  Future<Response> get(String path) => _dio.get(path);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}