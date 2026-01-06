import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final payload = await apiClient.post("/auth/register", {
      "email": email,
      "password": password,
    });
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await apiClient.post("/auth/login", {
      "email": email,
      "password": password,
    });
    return AuthSession.fromJson(payload);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final payload = await apiClient.post("/auth/refresh", {
      "refreshToken": refreshToken,
    });
    return AuthTokens(
      accessToken: payload["accessToken"] as String,
      refreshToken: payload["refreshToken"] as String,
    );
  }

  Future<void> logout(String refreshToken) async {
    await apiClient.post("/auth/logout", {"refreshToken": refreshToken});
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});
}
