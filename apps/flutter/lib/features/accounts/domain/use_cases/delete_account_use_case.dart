import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";

class DeleteAccountUseCase {
  final AccountRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.delete(id);
  }
}
