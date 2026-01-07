import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/accounts/data/datasources/account_remote_data_source.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remote;

  AccountRepositoryImpl(this.remote);

  @override
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

  @override
  Future<Account> create({
    required String name,
    required String type,
    String currency = "BRL",
    bool isActive = true,
  }) async {
    final payload = await remote.create(
      name: name,
      type: type,
      currency: currency,
      isActive: isActive,
    );
    return Account.fromJson(payload);
  }

  @override
  Future<Account> update(
    String id, {
    required String name,
    required String type,
    required String currency,
    required bool isActive,
  }) async {
    final payload = await remote.update(
      id,
      name: name,
      type: type,
      currency: currency,
      isActive: isActive,
    );
    return Account.fromJson(payload);
  }

  @override
  Future<void> delete(String id) {
    return remote.delete(id);
  }
}
