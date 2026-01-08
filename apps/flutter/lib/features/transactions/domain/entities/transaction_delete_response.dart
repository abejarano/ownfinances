class TransactionDeleteResponse {
  final bool ok;
  final Map<String, dynamic>? impact;

  const TransactionDeleteResponse({
    required this.ok,
    required this.impact,
  });

  factory TransactionDeleteResponse.fromJson(Map<String, dynamic> json) {
    return TransactionDeleteResponse(
      ok: json["ok"] as bool? ?? false,
      impact: json["impact"] as Map<String, dynamic>?,
    );
  }
}

