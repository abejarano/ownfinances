import "package:ownfinances/core/result/result.dart";
import "package:ownfinances/features/auth/domain/entities/auth_models.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Result<AuthSession>> execute(String email, String password) {
    return repository.login(email, password);
  }
}
