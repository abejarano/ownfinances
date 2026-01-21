import "package:ownfinances/core/result/result.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";

abstract class AuthRepository {
  Future<Result<AuthSession>> login(String email, String password);
  Future<Result<AuthSession>> register(
    String email,
    String password, {
    String? name,
  });
  Future<Result<AuthSession>> socialLogin(
    String provider,
    String token,
    String? email,
    String? name,
  );
  Future<Result<void>> logout(String refreshToken);
  Future<AuthSession?> getSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
  Future<String?> getMessage();
  Future<void> setMessage(String? message);
}
