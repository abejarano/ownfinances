import "package:ownfinances/features/auth/domain/entities/auth_models.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";

class RestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSessionUseCase(this.repository);

  Future<AuthSession?> execute() {
    return repository.getSession();
  }
}
