import "package:ownfinances/features/auth/application/state/auth_state.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";
import "package:ownfinances/features/auth/domain/use_cases/login_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/logout_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/register_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/restore_session_use_case.dart";
import "package:flutter/material.dart";

class AuthController extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final AuthRepository repository;
  AuthState _state = AuthState.initial;

  AuthController(
    this.loginUseCase,
    this.registerUseCase,
    this.logoutUseCase,
    this.restoreSessionUseCase,
    this.repository,
  );

  AuthState get state => _state;
  bool get isAuthenticated => _state.session != null;

  Future<void> restoreSession() async {
    final session = await restoreSessionUseCase.execute();
    final message = await repository.getMessage();
    if (session != null) {
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        message: message,
      );
    } else {
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
        message: message,
      );
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, message: null);
    notifyListeners();
    final result = await loginUseCase.execute(email, password);
    if (result.isSuccess) {
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        session: result.data,
      );
      notifyListeners();
      return null;
    }
    _state = _state.copyWith(
      status: AuthStatus.unauthenticated,
      message: result.failure?.message,
    );
    notifyListeners();
    return result.failure?.message;
  }

  Future<String?> register(String email, String password) async {
    _state = _state.copyWith(status: AuthStatus.loading, message: null);
    notifyListeners();
    final result = await registerUseCase.execute(email, password);
    if (result.isSuccess) {
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        session: result.data,
      );
      notifyListeners();
      return null;
    }
    _state = _state.copyWith(
      status: AuthStatus.unauthenticated,
      message: result.failure?.message,
    );
    notifyListeners();
    return result.failure?.message;
  }

  Future<void> logout() async {
    final session = _state.session;
    if (session != null) {
      await logoutUseCase.execute(session.refreshToken);
    }
    _state = _state.copyWith(status: AuthStatus.unauthenticated, session: null);
    notifyListeners();
  }

  Future<void> clearMessage() async {
    await repository.setMessage(null);
    _state = _state.copyWith(message: null);
    notifyListeners();
  }
}
