import "package:ownfinances/features/auth/domain/entities/auth_models.dart";

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthSession? session;
  final String? message;
  static const _unset = Object();

  const AuthState({required this.status, this.session, this.message});

  AuthState copyWith({
    AuthStatus? status,
    Object? session = _unset,
    String? message,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session == _unset ? this.session : session as AuthSession?,
      message: message,
    );
  }

  static const AuthState initial = AuthState(status: AuthStatus.initial);
}
