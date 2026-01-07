import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";

class ListAccountsUseCase {
  final AccountRepository repository;

  ListAccountsUseCase(this.repository);

  Future<Paginated<Account>> execute({
    String? type,
    bool? isActive,
    String? query,
  }) {
    return repository.list(type: type, isActive: isActive, query: query);
  }
}
