import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";

class CreateCategoryUseCase {
  final CategoryRepository repository;

  CreateCategoryUseCase(this.repository);

  Future<Category> execute({
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    bool isActive = true,
  }) {
    return repository.create(
      name: name,
      kind: kind,
      parentId: parentId,
      color: color,
      icon: icon,
      isActive: isActive,
    );
  }
}
