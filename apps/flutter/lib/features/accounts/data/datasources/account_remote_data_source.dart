import "package:ownfinances/core/infrastructure/api/api_client.dart";

class AccountRemoteDataSource {
  final ApiClient apiClient;

  AccountRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list({
    String? type,
    bool? isActive,
    String? query,
  }) async {
    final response = await apiClient.get(
      "/accounts",
      query: {
        if (type != null) "type": type,
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
    required String type,
    String currency = "BRL",
    bool isActive = true,
    String? bankType,
  }) async {
    final response = await apiClient.post("/accounts", {
      "name": name,
      "type": type,
      "currency": currency,
      "isActive": isActive,
      if (bankType != null) "bankType": bankType,
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id, {
    required String name,
    required String type,
    required String currency,
    required bool isActive,
    String? bankType,
  }) async {
    final response = await apiClient.put("/accounts/$id", {
      "name": name,
      "type": type,
      "currency": currency,
      "isActive": isActive,
      if (bankType != null) "bankType": bankType,
    });
    return response as Map<String, dynamic>;
  }

  Future<void> delete(String id) async {
    await apiClient.delete("/accounts/$id");
  }
}
