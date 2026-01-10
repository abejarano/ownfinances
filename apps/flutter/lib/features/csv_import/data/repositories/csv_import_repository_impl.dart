import "package:ownfinances/features/csv_import/domain/entities/import_job.dart";
import "package:ownfinances/features/csv_import/domain/entities/import_preview.dart";
import "package:ownfinances/features/csv_import/domain/repositories/csv_import_repository.dart";
import "package:ownfinances/features/csv_import/data/datasources/csv_import_remote_data_source.dart";

class CsvImportRepositoryImpl implements CsvImportRepository {
  final CsvImportRemoteDataSource remote;

  CsvImportRepositoryImpl(this.remote);

  @override
  Future<ImportPreview> preview(String accountId, String csvContent) async {
    final result = await remote.preview(accountId, csvContent);
    return ImportPreview.fromJson(result);
  }

  @override
  Future<Map<String, dynamic>> import(String accountId, String csvContent) async {
    return remote.import(accountId, csvContent);
  }

  @override
  Future<ImportJob> getImportJob(String jobId) async {
    final result = await remote.getImportJob(jobId);
    return ImportJob.fromJson(result);
  }
}
