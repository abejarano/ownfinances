import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";

class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  Future<Account> execute(
    String id, {
    required String name,
    required String type,
    required String currency,
    required bool isActive,
  }) {
    return repository.update(
      id,
      name: name,
      type: type,
      currency: currency,
      isActive: isActive,
    );
  }
}
