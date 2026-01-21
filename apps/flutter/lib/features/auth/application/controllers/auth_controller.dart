import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:sign_in_with_apple/sign_in_with_apple.dart";
import "package:ownfinances/features/auth/application/state/auth_state.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";

class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  AuthState _state = AuthState.initial;

  AuthController(this.repository);

  AuthState get state => _state;
  bool get isAuthenticated => _state.session != null;

  Future<void> restoreSession() async {
    final session = await repository.getSession();
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
    final result = await repository.login(email, password);
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
    final result = await repository.register(email, password);
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

  Future<String?> loginWithGoogle() async {
    _state = _state.copyWith(status: AuthStatus.loading, message: null);
    notifyListeners();
    try {
      print("Event: login_social_started provider=google");
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) {
        _state = _state.copyWith(
          status: AuthStatus.unauthenticated,
          message: "Login cancelado",
        );
        notifyListeners();
        return "Login cancelado";
      }

      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null) {
        throw Exception("Falha ao obter token do Google");
      }

      final result = await repository.socialLogin(
        "google",
        token,
        account.email,
        account.displayName,
      );

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
    } catch (e) {
      print("Event: login_social_failed provider=google error=$e");
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        message: "Não foi possível entrar com Google agora.",
      );
      notifyListeners();
      return "Erro no login Google";
    }
  }

  Future<String?> loginWithApple() async {
    _state = _state.copyWith(status: AuthStatus.loading, message: null);
    notifyListeners();
    try {
      print("Event: login_social_started provider=apple");
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final token = credential.identityToken;
      if (token == null) {
        throw Exception("Falha ao obter token da Apple");
      }

      final name = credential.givenName != null
          ? "${credential.givenName} ${credential.familyName ?? ''}"
          : null;

      final result = await repository.socialLogin(
        "apple",
        token,
        credential.email,
        name != null && name.trim().isNotEmpty ? name.trim() : null,
      );

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
    } catch (e) {
      // Check for user cancellation (error code 1001 usually, but generic catch is safer for MVP)
      final msg = e.toString().contains("Authorization failed: Canceled")
          ? "Login cancelado"
          : "Não foi possível entrar com Apple agora.";
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        message: msg,
      );
      notifyListeners();
      return msg;
    }
  }

  Future<void> logout() async {
    final session = _state.session;
    if (session != null) {
      await repository.logout(session.refreshToken);
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
