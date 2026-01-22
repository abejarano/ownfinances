import "package:ownfinances/core/error/failure.dart";
import "package:ownfinances/core/result/result.dart";
import "package:ownfinances/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";

class AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage storage;

  AuthRepository({required this.remote, required this.storage});

  Future<Result<AuthSession>> login(String email, String password) async {
    try {
      final session = await remote.login(email, password);
      await storage.save(session);
      return Result.success(session);
    } catch (_) {
      return Result.error(const UnauthorizedFailure("Credenciais inválidas"));
    }
  }

  Future<Result<AuthSession>> register(
    String email,
    String password, {
    String? name,
  }) async {
    try {
      final session = await remote.register(email, password, name: name);
      await storage.save(session);
      return Result.success(session);
    } catch (_) {
      return Result.error(const ValidationFailure("Email já registrado"));
    }
  }

  Future<Result<AuthSession>> socialLogin(
    String provider,
    String token,
    String? email,
    String? name,
  ) async {
    try {
      final session = await remote.socialLogin(provider, token, email, name);
      await storage.save(session);
      return Result.success(session);
    } catch (_) {
      return Result.error(const UnauthorizedFailure("Falha no login social"));
    }
  }

  Future<Result<void>> logout(String refreshToken) async {
    try {
      await remote.logout(refreshToken);
      await storage.clear();
      return Result.success(null);
    } catch (_) {
      await storage.clear();
      return Result.error(const UnknownFailure("Erro ao sair"));
    }
  }

  Future<AuthSession?> getSession() async {
    final state = await storage.read();
    return state.session;
  }

  Future<void> saveSession(AuthSession session) async {
    await storage.save(session);
  }

  Future<void> clearSession() async {
    await storage.clear();
  }

  Future<String?> getMessage() async {
    final state = await storage.read();
    return state.message;
  }

  Future<void> setMessage(String? message) async {
    await storage.setMessage(message);
  }
}
