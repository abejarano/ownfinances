import "dart:async";
import "package:ownfinances/core/infrastructure/websocket/websocket_client.dart";

class WebSocketNotifications {
  final WebSocketClient client;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  WebSocketNotifications(this.client);

  void listen(Function(Map<String, dynamic>) onMessage) {
    _subscription?.cancel();
    _subscription = client.messages.listen(onMessage);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
