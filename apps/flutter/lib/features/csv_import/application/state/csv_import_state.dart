class CsvImportState {
  final bool isLoading;
  final String? selectedAccountId;
  final int month;
  final int year;
  final String? csvContent;
  final String? error;

  const CsvImportState({
    required this.isLoading,
    required this.month,
    required this.year,
    this.selectedAccountId,
    this.csvContent,
    this.error,
  });

  CsvImportState copyWith({
    bool? isLoading,
    String? selectedAccountId,
    String? csvContent,
    String? error,
    int? month,
    int? year,
  }) {
    return CsvImportState(
      isLoading: isLoading ?? this.isLoading,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      csvContent: csvContent ?? this.csvContent,
      error: error,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  factory CsvImportState.initial() {
    var now = DateTime.now();

    return CsvImportState(isLoading: false, month: now.month, year: now.year);
  }
}
