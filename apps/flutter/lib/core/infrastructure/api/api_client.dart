import "dart:convert";

import "package:http/http.dart" as http;
import "package:http_parser/http_parser.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";

class ApiClient {
  final String baseUrl;
  final TokenStorage storage;
  final http.Client _client;

  ApiClient({required this.baseUrl, required this.storage, http.Client? client})
    : _client = client ?? http.Client();

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _send("GET", path, query: query);
    return _parse(response);
  }

  Future<dynamic> post(
    String path,
    dynamic body, {
    Map<String, String>? query,
    bool isMultipart = false,
  }) async {
    final response = await _send(
      "POST",
      path,
      body: body,
      query: query,
      isMultipart: isMultipart,
    );
    return _parse(response);
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) async {
    final response = await _send("PUT", path, body: body, query: query);
    return _parse(response);
  }

  Future<dynamic> delete(String path, {Map<String, String>? query}) async {
    final response = await _send("DELETE", path, query: query);
    return _parse(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    dynamic body,
    bool retry = true,
    Map<String, String>? query,
    bool isMultipart = false,
  }) async {
    final session = (await storage.read()).session;
    final headers = <String, String>{
      if (session != null) "Authorization": "Bearer ${session.accessToken}",
    };

    final uri = Uri.parse("$baseUrl$path").replace(queryParameters: query);

    http.BaseRequest request;
    if (isMultipart && body is Map<String, dynamic>) {
      // Multipart request
      final multipartRequest = http.MultipartRequest(method, uri);
      multipartRequest.headers.addAll(headers);

      body.forEach((key, value) {
        if (value is http.MultipartFile) {
          multipartRequest.files.add(value);
        } else if (value is String && key == "file") {
          // Legacy support or direct string upload
          final bytes = utf8.encode(value);
          multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              key,
              bytes,
              filename: "import.csv",
              contentType: MediaType("application", "octet-stream"),
            ),
          );
        } else if (value != null) {
          multipartRequest.fields[key] = value.toString();
        }
      });

      request = multipartRequest;
    } else {
      // JSON request
      final jsonRequest = http.Request(method, uri);

      if (body != null) {
        headers["Content-Type"] = "application/json";
        jsonRequest.body = jsonEncode(body);
      }

      jsonRequest.headers.addAll(headers);
      request = jsonRequest;
    }

    final response = await _client.send(request).then(http.Response.fromStream);

    if (response.statusCode == 401 && retry && !_isAuthPath(path)) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return _send(
          method,
          path,
          body: body,
          retry: false,
          isMultipart: isMultipart,
        );
      }
      await storage.setMessage("Sessao expirada");
      await storage.clear();
    }

    return response;
  }

  Future<bool>? _refreshFuture;

  Future<bool> _refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _doRefreshToken();
    try {
      final result = await _refreshFuture;
      return result ?? false;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefreshToken() async {
    final state = await storage.read();
    final session = state.session;
    if (session == null) return false;

    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/auth/refresh"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": session.refreshToken}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
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
    } catch (_) {
      return false;
    }
  }

  dynamic _parse(http.Response response) {
    if (response.statusCode >= 400) {
      String message = "Erro inesperado";
      if (response.body.isNotEmpty) {
        try {
          // Add support for simple string response types (legacy)
          // If body starts with {, it's likely JSON. If not, it's a string.
          if (response.body.trim().startsWith("{")) {
            final payload = jsonDecode(response.body) as Map<String, dynamic>;
            if (payload["error"] is String) {
              message = payload["error"] as String;
            } else if (payload["message"] is String) {
              // Some frameworks use 'message'
              message = payload["message"] as String;
            }
          } else {
            // Plain text error from legacy endpoints
            message = response.body;
          }
        } catch (_) {
          // Fallback if parsing fails but body exists (e.g. plain text)
          message = response.body;
        }
      }
      throw ApiException(message, response.statusCode);
    }
    if (response.body.isNotEmpty) {
      return jsonDecode(response.body);
    }
    return {};
  }

  bool _isAuthPath(String path) {
    return path.startsWith("/auth/");
  }
}
