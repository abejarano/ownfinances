import "package:ownfinances/features/categories/domain/entities/category.dart";

class CategoriesState {
  final bool isLoading;
  final List<Category> items;
  final String? error;

  const CategoriesState({
    required this.isLoading,
    required this.items,
    this.error,
  });

  CategoriesState copyWith({
    bool? isLoading,
    List<Category>? items,
    String? error,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }

  static const initial = CategoriesState(isLoading: false, items: []);
}
