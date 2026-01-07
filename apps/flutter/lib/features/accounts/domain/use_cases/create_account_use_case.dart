import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";

class CreateAccountUseCase {
  final AccountRepository repository;

  CreateAccountUseCase(this.repository);

  Future<Account> execute({
    required String name,
    required String type,
    String currency = "BRL",
    bool isActive = true,
  }) {
    return repository.create(
      name: name,
      type: type,
      currency: currency,
      isActive: isActive,
    );
  }
}
