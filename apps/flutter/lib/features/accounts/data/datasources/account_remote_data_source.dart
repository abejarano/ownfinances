import "package:ownfinances/core/infrastructure/api/api_client.dart";

class AccountRemoteDataSource {
  final ApiClient apiClient;

  AccountRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list({
    String? type,
    bool? isActive,
    String? query,
  }) {
    return apiClient.get(
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
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String type,
    String currency = "BRL",
    bool isActive = true,
  }) {
    return apiClient.post("/accounts", {
      "name": name,
      "type": type,
      "currency": currency,
      "isActive": isActive,
    });
  }

  Future<Map<String, dynamic>> update(
    String id, {
    required String name,
    required String type,
    required String currency,
    required bool isActive,
  }) {
    return apiClient.put("/accounts/$id", {
      "name": name,
      "type": type,
      "currency": currency,
      "isActive": isActive,
    });
  }

  Future<void> delete(String id) async {
    await apiClient.delete("/accounts/$id");
  }
}
