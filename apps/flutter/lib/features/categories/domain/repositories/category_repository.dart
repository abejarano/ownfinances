import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";

abstract class CategoryRepository {
  Future<Paginated<Category>> list({
    String? kind,
    bool? isActive,
    String? query,
  });

  Future<Category> create({
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    bool isActive = true,
  });

  Future<Category> update(
    String id, {
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    required bool isActive,
  });

  Future<void> delete(String id);
}
