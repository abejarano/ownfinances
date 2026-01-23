class TransactionFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? categoryId;
  final String? accountId;
  final String? type;
  final String? status;
  final String? query;
  final int? limit;
  final int? page;

  const TransactionFilters({
    this.dateFrom,
    this.dateTo,
    this.categoryId,
    this.accountId,
    this.type,
    this.status,
    this.query,
    this.limit,
    this.page,
  });

  TransactionFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    String? accountId,
    String? type,
    String? status,
    String? query,
    int? limit,
    int? page,
  }) {
    return TransactionFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      status: status ?? this.status,
      query: query ?? this.query,
      limit: limit ?? this.limit,
      page: page ?? this.page,
    );
  }
}
