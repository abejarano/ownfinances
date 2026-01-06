import "dart:convert";
import "dart:html" as html;

import "../../domain/entities/auth_models.dart";
import "token_storage.dart";

class TokenStorageImpl implements TokenStorage {
  static const _sessionKey = "of_session";
  static const _messageKey = "of_session_message";
  static const _expiresKey = "of_session_expires_at";

  final void Function(AuthStorageState state) _onChanged;

  TokenStorageImpl({required void Function(AuthStorageState state) onChanged})
    : _onChanged = onChanged;

  @override
  Future<AuthStorageState> read() async {
    final raw = html.window.localStorage[_sessionKey];
    final message = html.window.localStorage[_messageKey];
    final expiresRaw = html.window.localStorage[_expiresKey];

    if (expiresRaw != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiresRaw),
      );
      if (DateTime.now().isAfter(expiresAt)) {
        await clear();
        return const AuthStorageState(
          session: null,
          message: "Sessao expirada",
        );
      }
    }

    if (raw == null) {
      return AuthStorageState(session: null, message: message);
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return AuthStorageState(
      session: AuthSession.fromJson(data),
      message: message,
    );
  }

  @override
  Future<void> save(AuthSession session) async {
    html.window.localStorage[_sessionKey] = jsonEncode(session.toJson());
    html.window.localStorage[_expiresKey] = DateTime.now()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch
        .toString();
    _onChanged(AuthStorageState(session: session));
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_sessionKey);
    html.window.localStorage.remove(_expiresKey);
    _onChanged(const AuthStorageState(session: null));
  }

  @override
  Future<void> setMessage(String? message) async {
    if (message == null) {
      html.window.localStorage.remove(_messageKey);
    } else {
      html.window.localStorage[_messageKey] = message;
    }
    _onChanged(AuthStorageState(message: message));
  }
}
