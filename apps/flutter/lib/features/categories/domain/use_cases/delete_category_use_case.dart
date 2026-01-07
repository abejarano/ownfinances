import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";

class DeleteCategoryUseCase {
  final CategoryRepository repository;

  DeleteCategoryUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.delete(id);
  }
}
