import "dart:convert";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "../../domain/entities/auth_models.dart";
import "token_storage.dart";

class TokenStorageImpl implements TokenStorage {
  static const _sessionKey = "of_session";
  static const _messageKey = "of_session_message";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final void Function(AuthStorageState state) _onChanged;

  TokenStorageImpl({required void Function(AuthStorageState state) onChanged})
    : _onChanged = onChanged;

  @override
  Future<AuthStorageState> read() async {
    final raw = await _storage.read(key: _sessionKey);
    final message = await _storage.read(key: _messageKey);
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
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
    _onChanged(AuthStorageState(session: session));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    _onChanged(const AuthStorageState(session: null));
  }

  @override
  Future<void> setMessage(String? message) async {
    if (message == null) {
      await _storage.delete(key: _messageKey);
    } else {
      await _storage.write(key: _messageKey, value: message);
    }
    _onChanged(AuthStorageState(message: message));
  }
}
