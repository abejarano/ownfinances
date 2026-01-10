import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";

abstract class AccountRepository {
  Future<Paginated<Account>> list({
    String? type,
    bool? isActive,
    String? query,
  });

  Future<Account> create({
    required String name,
    required String type,
    String currency = "BRL",
    bool isActive = true,
    String? bankType,
  });

  Future<Account> update(
    String id, {
    required String name,
    required String type,
    required String currency,
    required bool isActive,
    String? bankType,
  });

  Future<void> delete(String id);
}
