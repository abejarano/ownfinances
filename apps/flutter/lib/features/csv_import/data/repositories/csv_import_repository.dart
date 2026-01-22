import "package:ownfinances/features/csv_import/domain/entities/import_job.dart";
import "package:ownfinances/features/csv_import/domain/entities/import_preview.dart";
import "package:ownfinances/features/csv_import/data/datasources/csv_import_remote_data_source.dart";

class CsvImportRepository {
  final CsvImportRemoteDataSource remote;

  CsvImportRepository(this.remote);

  Future<ImportPreview> preview(String accountId, String csvContent) async {
    final result = await remote.preview(accountId, csvContent);
    return ImportPreview.fromJson(result);
  }

  Future<Map<String, dynamic>> import(String accountId, String csvContent) async {
    return remote.import(accountId, csvContent);
  }

  Future<ImportJob> getImportJob(String jobId) async {
    final result = await remote.getImportJob(jobId);
    return ImportJob.fromJson(result);
  }
}
