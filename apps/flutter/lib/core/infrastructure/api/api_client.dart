import "dart:convert";

import "package:http/http.dart" as http;
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";

class ApiClient {
  final String baseUrl;
  final TokenStorage storage;
  final http.Client _client;

  ApiClient({required this.baseUrl, required this.storage, http.Client? client})
    : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send("GET", path, query: query);
    return _parse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) async {
    final response = await _send("POST", path, body: body, query: query);
    return _parse(response);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) async {
    final response = await _send("PUT", path, body: body, query: query);
    return _parse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send("DELETE", path, query: query);
    return _parse(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
    Map<String, String>? query,
  }) async {
    final session = (await storage.read()).session;
    final headers = <String, String>{
      "Content-Type": "application/json",
      if (session != null) "Authorization": "Bearer ${session.accessToken}",
    };

    final uri = Uri.parse("$baseUrl$path").replace(queryParameters: query);
    final response = await _client
        .send(
          http.Request(method, uri)
            ..headers.addAll(headers)
            ..body = body == null ? "" : jsonEncode(body),
        )
        .then(http.Response.fromStream);

    if (response.statusCode == 401 && retry && !_isAuthPath(path)) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return _send(method, path, body: body, retry: false);
      }
      await storage.setMessage("Sessao expirada");
      await storage.clear();
    }

    return response;
  }

  Future<bool> _refreshToken() async {
    final state = await storage.read();
    final session = state.session;
    if (session == null) return false;

    final response = await _client.post(
      Uri.parse("$baseUrl/auth/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refreshToken": session.refreshToken}),
    );

    if (response.statusCode != 200) {
      return false;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final updated = AuthSession(
      user: session.user,
      accessToken: payload["accessToken"] as String,
      refreshToken: payload["refreshToken"] as String,
    );
    await storage.save(updated);
    return true;
  }

  Map<String, dynamic> _parse(http.Response response) {
    if (response.statusCode >= 400) {
      String message = "Erro inesperado";
      if (response.body.isNotEmpty) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        if (payload["error"] is String) {
          message = payload["error"] as String;
        }
      }
      throw ApiException(message, response.statusCode);
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  bool _isAuthPath(String path) {
    return path.startsWith("/auth/") || path == "/me";
  }
}
