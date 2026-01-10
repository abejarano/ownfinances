class ImportPreview {
  final List<ImportPreviewRow> rows;
  final int totalRows;

  const ImportPreview({
    required this.rows,
    required this.totalRows,
  });

  factory ImportPreview.fromJson(Map<String, dynamic> json) {
    return ImportPreview(
      rows: (json["rows"] as List<dynamic>?)
              ?.map((item) => ImportPreviewRow.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      totalRows: (json["totalRows"] as num?)?.toInt() ?? 0,
    );
  }
}

class ImportPreviewRow {
  final int row;
  final String date;
  final double amount;
  final String type;
  final String? note;

  const ImportPreviewRow({
    required this.row,
    required this.date,
    required this.amount,
    required this.type,
    this.note,
  });

  factory ImportPreviewRow.fromJson(Map<String, dynamic> json) {
    return ImportPreviewRow(
      row: (json["row"] as num?)?.toInt() ?? 0,
      date: json["date"] as String,
      amount: (json["amount"] as num?)?.toDouble() ?? 0,
      type: json["type"] as String,
      note: json["note"] as String?,
    );
  }
}
