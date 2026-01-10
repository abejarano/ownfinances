import "dart:async";
import "dart:convert";
import "package:web_socket_channel/web_socket_channel.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";

class WebSocketClient {
  final String baseUrl;
  final TokenStorage tokenStorage;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;

  WebSocketClient({
    required this.baseUrl,
    required this.tokenStorage,
  });

  Stream<Map<String, dynamic>> get messages {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final session = (await tokenStorage.read()).session;
      if (session == null) {
        throw Exception("No hay sesión activa");
      }

      final wsUrl = baseUrl.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://");
      final uri = Uri.parse("$wsUrl/ws?token=${session.accessToken}");

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _messageController?.add(data);
          } catch (e) {
            print("Error parsing WebSocket message: $e");
          }
        },
        onError: (error) {
          print("WebSocket error: $error");
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );

      // Enviar mensaje de autenticación
      _channel!.sink.add(jsonEncode({
        "type": "auth",
        "token": session.accessToken,
      }));

      _isConnected = true;
    } catch (e) {
      print("Error connecting WebSocket: $e");
      _isConnected = false;
      rethrow;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}
