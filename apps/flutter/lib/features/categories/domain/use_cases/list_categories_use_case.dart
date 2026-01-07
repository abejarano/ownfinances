import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";

class ListCategoriesUseCase {
  final CategoryRepository repository;

  ListCategoriesUseCase(this.repository);

  Future<Paginated<Category>> execute({
    String? kind,
    bool? isActive,
    String? query,
  }) {
    return repository.list(kind: kind, isActive: isActive, query: query);
  }
}
