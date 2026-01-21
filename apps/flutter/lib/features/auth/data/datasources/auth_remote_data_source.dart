import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<AuthSession> register(
    String email,
    String password, {
    String? name,
  }) async {
    final payload = await apiClient.post("/auth/register", {
      "email": email,
      "password": password,
      if (name != null) "name": name,
    });
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> login(String email, String password) async {
    final payload = await apiClient.post("/auth/login", {
      "email": email,
      "password": password,
    });
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> socialLogin(
    String provider,
    String token,
    String? email,
    String? name,
  ) async {
    final payload = await apiClient.post("/auth/social-login", {
      "provider": provider,
      "token": token,
      if (email != null) "email": email,
      if (name != null) "name": name,
    });
    return AuthSession.fromJson(payload);
  }

  Future<void> logout(String refreshToken) async {
    await apiClient.post("/auth/logout", {"refreshToken": refreshToken});
  }
}
