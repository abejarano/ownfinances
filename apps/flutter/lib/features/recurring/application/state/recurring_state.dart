import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';

class RecurringState {
  final bool isLoading;
  final String? error;
  final List<RecurringRule> items;
  final List<RecurringPreviewItem> previewItems;
  final int toGenerateCount;
  final String currentMonth;

  const RecurringState({
    required this.isLoading,
    this.error,
    required this.items,
    required this.previewItems,
    this.toGenerateCount = 0,
    this.currentMonth = '',
  });

  factory RecurringState.initial() {
    return const RecurringState(isLoading: false, items: [], previewItems: []);
  }

  RecurringState copyWith({
    bool? isLoading,
    String? error,
    List<RecurringRule>? items,
    List<RecurringPreviewItem>? previewItems,
    int? toGenerateCount,
    String? currentMonth,
  }) {
    return RecurringState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      previewItems: previewItems ?? this.previewItems,
      toGenerateCount: toGenerateCount ?? this.toGenerateCount,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }
}
