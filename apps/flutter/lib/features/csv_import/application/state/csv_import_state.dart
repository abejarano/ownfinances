import "package:ownfinances/features/csv_import/domain/entities/import_preview.dart";
import "package:ownfinances/features/csv_import/domain/entities/import_job.dart";

class CsvImportState {
  final bool isLoading;
  final String? selectedAccountId;
  final String? csvContent;
  final ImportPreview? preview;
  final String? jobId;
  final ImportJob? importJob;
  final String? error;

  const CsvImportState({
    required this.isLoading,
    this.selectedAccountId,
    this.csvContent,
    this.preview,
    this.jobId,
    this.importJob,
    this.error,
  });

  CsvImportState copyWith({
    bool? isLoading,
    String? selectedAccountId,
    String? csvContent,
    ImportPreview? preview,
    String? jobId,
    ImportJob? importJob,
    String? error,
  }) {
    return CsvImportState(
      isLoading: isLoading ?? this.isLoading,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      csvContent: csvContent ?? this.csvContent,
      preview: preview ?? this.preview,
      jobId: jobId ?? this.jobId,
      importJob: importJob ?? this.importJob,
      error: error,
    );
  }

  factory CsvImportState.initial() {
    return const CsvImportState(isLoading: false);
  }
}
