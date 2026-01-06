import "../../domain/entities/auth_models.dart";
import "token_storage_io.dart" if (dart.library.html) "token_storage_web.dart";

abstract class TokenStorage {
  factory TokenStorage({
    required void Function(AuthStorageState state) onChanged,
  }) = TokenStorageImpl;

  Future<AuthStorageState> read();
  Future<void> save(AuthSession session);
  Future<void> clear();
  Future<void> setMessage(String? message);
}
