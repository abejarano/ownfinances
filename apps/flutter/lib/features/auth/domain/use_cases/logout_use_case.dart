import "package:ownfinances/core/result/result.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Result<void>> execute(String refreshToken) {
    return repository.logout(refreshToken);
  }
}
