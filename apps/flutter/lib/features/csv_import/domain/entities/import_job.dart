class ImportJob {
  final String id;
  final String userId;
  final String status;
  final String accountId;
  final String bankType;
  final int totalRows;
  final int imported;
  final int duplicates;
  final int errors;
  final List<ImportErrorDetail> errorDetails;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ImportJob({
    required this.id,
    required this.userId,
    required this.status,
    required this.accountId,
    required this.bankType,
    required this.totalRows,
    required this.imported,
    required this.duplicates,
    required this.errors,
    required this.errorDetails,
    required this.createdAt,
    this.completedAt,
  });

  factory ImportJob.fromJson(Map<String, dynamic> json) {
    return ImportJob(
      id: (json["importJobId"] ?? json["id"]) as String,
      userId: json["userId"] as String,
      status: json["status"] as String,
      accountId: json["accountId"] as String,
      bankType: json["bankType"] as String,
      totalRows: (json["totalRows"] as num?)?.toInt() ?? 0,
      imported: (json["imported"] as num?)?.toInt() ?? 0,
      duplicates: (json["duplicates"] as num?)?.toInt() ?? 0,
      errors: (json["errors"] as num?)?.toInt() ?? 0,
      errorDetails: (json["errorDetails"] as List<dynamic>?)
              ?.map((item) => ImportErrorDetail.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json["createdAt"] as String),
      completedAt: json["completedAt"] != null
          ? DateTime.tryParse(json["completedAt"] as String)
          : null,
    );
  }
}

class ImportErrorDetail {
  final int row;
  final String error;

  const ImportErrorDetail({
    required this.row,
    required this.error,
  });

  factory ImportErrorDetail.fromJson(Map<String, dynamic> json) {
    return ImportErrorDetail(
      row: (json["row"] as num?)?.toInt() ?? 0,
      error: json["error"] as String,
    );
  }
}
