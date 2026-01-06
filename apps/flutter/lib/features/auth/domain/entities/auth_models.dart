class AuthUser {
  final String id;
  final String email;
  final String? name;

  AuthUser({required this.id, required this.email, this.name});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json["id"] as String,
      email: json["email"] as String,
      name: json["name"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "email": email, "name": name};
}

class AuthSession {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json["user"] as Map<String, dynamic>),
      accessToken: json["accessToken"] as String,
      refreshToken: json["refreshToken"] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    "user": user.toJson(),
    "accessToken": accessToken,
    "refreshToken": refreshToken,
  };
}

class AuthStorageState {
  final AuthSession? session;
  final String? message;

  const AuthStorageState({this.session, this.message});
}
