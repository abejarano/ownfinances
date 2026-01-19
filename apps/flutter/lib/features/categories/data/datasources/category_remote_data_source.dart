import "package:ownfinances/core/infrastructure/api/api_client.dart";

class CategoryRemoteDataSource {
  final ApiClient apiClient;

  CategoryRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list({
    String? kind,
    bool? isActive,
    String? query,
  }) async {
    final response = await apiClient.get(
      "/categories",
      query: {
        if (kind != null) "kind": kind,
        if (isActive != null) "isActive": isActive.toString(),
        if (query != null && query.isNotEmpty) "q": query,
        "limit": "100",
        "page": "1",
        "sort": "name",
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    bool isActive = true,
  }) async {
    final response = await apiClient.post("/categories", {
      "name": name,
      "kind": kind,
      if (parentId != null && parentId.isNotEmpty) "parentId": parentId,
      if (color != null && color.isNotEmpty) "color": color,
      if (icon != null && icon.isNotEmpty) "icon": icon,
      "isActive": isActive,
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id, {
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    required bool isActive,
  }) async {
    final response = await apiClient.put("/categories/$id", {
      "name": name,
      "kind": kind,
      "parentId": parentId,
      "color": color,
      "icon": icon,
      "isActive": isActive,
    });
    return response as Map<String, dynamic>;
  }

  Future<void> delete(String id) async {
    await apiClient.delete("/categories/$id");
  }
}
