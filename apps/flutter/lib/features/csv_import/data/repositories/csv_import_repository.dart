import "package:ownfinances/features/csv_import/domain/entities/import_preview.dart";
import "package:ownfinances/features/csv_import/data/datasources/csv_import_remote_data_source.dart";

class CsvImportRepository {
  final CsvImportRemoteDataSource remote;

  CsvImportRepository(this.remote);

  Future<ImportPreview> preview(String accountId, String csvContent) async {
    final result = await remote.preview(accountId, csvContent);
    return ImportPreview.fromJson(result);
  }

  Future<void> import(String accountId, String csvContent) async {
    await remote.import(accountId, csvContent);
  }
}
