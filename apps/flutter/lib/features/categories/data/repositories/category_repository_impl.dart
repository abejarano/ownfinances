import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/categories/data/datasources/category_remote_data_source.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remote;

  CategoryRepositoryImpl(this.remote);

  @override
  Future<Paginated<Category>> list({
    String? kind,
    bool? isActive,
    String? query,
  }) async {
    final payload = await remote.list(
      kind: kind,
      isActive: isActive,
      query: query,
    );
    final results = (payload["results"] as List<dynamic>? ?? [])
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
    return Paginated(
      nextPage: payload["nextPag"] as int?,
      count: payload["count"] as int? ?? results.length,
      results: results,
    );
  }

  @override
  Future<Category> create({
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    bool isActive = true,
  }) async {
    final payload = await remote.create(
      name: name,
      kind: kind,
      parentId: parentId,
      color: color,
      icon: icon,
      isActive: isActive,
    );
    return Category.fromJson(payload);
  }

  @override
  Future<Category> update(
    String id, {
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    required bool isActive,
  }) async {
    final payload = await remote.update(
      id,
      name: name,
      kind: kind,
      parentId: parentId,
      color: color,
      icon: icon,
      isActive: isActive,
    );
    return Category.fromJson(payload);
  }

  @override
  Future<void> delete(String id) {
    return remote.delete(id);
  }
}
