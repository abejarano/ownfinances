import "package:ownfinances/features/banks/data/datasources/bank_remote_data_source.dart";
import "package:ownfinances/features/banks/domain/entities/bank.dart";

class BankRepository {
  final BankRemoteDataSource remote;

  BankRepository(this.remote);

  Future<List<Bank>> list({String? country}) async {
    final payload = await remote.list(country: country);
    return payload
        .map((item) => Bank.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
