import "package:ownfinances/features/countries/data/datasources/country_remote_data_source.dart";
import "package:ownfinances/features/countries/domain/entities/country.dart";

class CountryRepository {
  final CountryRemoteDataSource remote;

  CountryRepository(this.remote);

  Future<List<Country>> list() async {
    final payload = await remote.list();
    return payload
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
