import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/auth/application/state/auth_state.dart";
import "package:ownfinances/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/features/auth/data/repositories/auth_repository_impl.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";
import "package:ownfinances/features/auth/domain/use_cases/login_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/logout_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/register_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/restore_session_use_case.dart";

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(onChanged: (_) {});
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(baseUrl: "http://localhost:3000", storage: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final remote = AuthRemoteDataSource(ref.watch(apiClientProvider));
  return AuthRepositoryImpl(remote: remote, storage: storage);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repo = ref.watch(authRepositoryProvider);
    final controller = AuthController(
      LoginUseCase(repo),
      RegisterUseCase(repo),
      LogoutUseCase(repo),
      RestoreSessionUseCase(repo),
      repo,
    );
    controller.restoreSession();
    return controller;
  },
);

class AuthController extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final AuthRepository repository;

  AuthController(
    this.loginUseCase,
    this.registerUseCase,
    this.logoutUseCase,
    this.restoreSessionUseCase,
    this.repository,
  ) : super(AuthState.initial);

  Future<void> restoreSession() async {
    final session = await restoreSessionUseCase.execute();
    final message = await repository.getMessage();
    if (session != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        message: message,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
        message: message,
      );
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await loginUseCase.execute(email, password);
    if (result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: result.data,
      );
      return null;
    }
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      message: result.failure?.message,
    );
    return result.failure?.message;
  }

  Future<String?> register(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await registerUseCase.execute(email, password);
    if (result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: result.data,
      );
      return null;
    }
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      message: result.failure?.message,
    );
    return result.failure?.message;
  }

  Future<void> logout() async {
    final session = state.session;
    if (session != null) {
      await logoutUseCase.execute(session.refreshToken);
    }
    state = state.copyWith(status: AuthStatus.unauthenticated, session: null);
  }

  Future<void> clearMessage() async {
    await repository.setMessage(null);
    state = state.copyWith(message: null);
  }
}
