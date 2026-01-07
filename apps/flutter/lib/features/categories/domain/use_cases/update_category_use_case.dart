import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";

class UpdateCategoryUseCase {
  final CategoryRepository repository;

  UpdateCategoryUseCase(this.repository);

  Future<Category> execute(
    String id, {
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    required bool isActive,
  }) {
    return repository.update(
      id,
      name: name,
      kind: kind,
      parentId: parentId,
      color: color,
      icon: icon,
      isActive: isActive,
    );
  }
}
