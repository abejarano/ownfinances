import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";
import "package:ownfinances/features/auth/data/repositories/auth_repository.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";

final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final authMessageProvider = StateProvider<String?>((ref) => null);

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(
    onChanged: (state) {
      ref.read(authSessionProvider.notifier).state = state.session;
      if (state.message != null) {
        ref.read(authMessageProvider.notifier).state = state.message;
      }
    },
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(baseUrl: "http://localhost:3000", storage: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(
    ref,
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
  controller.restoreSession();
  return controller;
});

class AuthController {
  final Ref ref;
  final AuthRepository repository;
  final TokenStorage storage;

  AuthController(this.ref, this.repository, this.storage);

  Future<void> restoreSession() async {
    final state = await storage.read();
    ref.read(authSessionProvider.notifier).state = state.session;
    if (state.message != null) {
      ref.read(authMessageProvider.notifier).state = state.message;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final session = await repository.login(email: email, password: password);
      await storage.save(session);
      return null;
    } catch (_) {
      return "Credenciais inválidas";
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final session = await repository.register(
        email: email,
        password: password,
      );
      await storage.save(session);
      return null;
    } catch (_) {
      return "Email já registrado";
    }
  }

  Future<void> logout() async {
    final session = ref.read(authSessionProvider);
    if (session != null) {
      try {
        await repository.logout(session.refreshToken);
      } catch (_) {
        // ignore
      }
    }
    await storage.clear();
  }

  Future<void> clearMessage() async {
    ref.read(authMessageProvider.notifier).state = null;
    await storage.setMessage(null);
  }
}
