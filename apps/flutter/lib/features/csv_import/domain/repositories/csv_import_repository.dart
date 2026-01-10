import "package:ownfinances/features/csv_import/domain/entities/import_job.dart";
import "package:ownfinances/features/csv_import/domain/entities/import_preview.dart";

abstract class CsvImportRepository {
  Future<ImportPreview> preview(String accountId, String csvContent);
  Future<Map<String, dynamic>> import(String accountId, String csvContent);
  Future<ImportJob> getImportJob(String jobId);
}
