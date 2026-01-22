import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/accounts/data/datasources/account_remote_data_source.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";

class AccountRepository {
  final AccountRemoteDataSource remote;

  AccountRepository(this.remote);

  Future<Paginated<Account>> list({
    String? type,
    bool? isActive,
    String? query,
  }) async {
    final payload = await remote.list(
      type: type,
      isActive: isActive,
      query: query,
    );
    final results = (payload["results"] as List<dynamic>? ?? [])
        .map((item) => Account.fromJson(item as Map<String, dynamic>))
        .toList();
    return Paginated(
      nextPage: payload["nextPag"] as int?,
      count: payload["count"] as int? ?? results.length,
      results: results,
    );
  }

  Future<Account> create({
    required String name,
    required String type,
    String currency = "BRL",
    bool isActive = true,
    String? bankType,
  }) async {
    final payload = await remote.create(
      name: name,
      type: type,
      currency: currency,
      isActive: isActive,
      bankType: bankType,
    );
    return Account.fromJson(payload["account"] as Map<String, dynamic>);
  }

  Future<Account> update(
    String id, {
    required String name,
    required String type,
    required String currency,
    required bool isActive,
    String? bankType,
  }) async {
    final payload = await remote.update(
      id,
      name: name,
      type: type,
      currency: currency,
      isActive: isActive,
      bankType: bankType,
    );
    return Account.fromJson(payload["account"] as Map<String, dynamic>);
  }

  Future<void> delete(String id) {
    return remote.delete(id);
  }
}
