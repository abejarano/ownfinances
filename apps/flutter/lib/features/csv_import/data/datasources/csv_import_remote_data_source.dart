import "package:ownfinances/core/infrastructure/api/api_client.dart";

class CsvImportRemoteDataSource {
  final ApiClient apiClient;

  CsvImportRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> preview(String accountId, String csvContent) async {
    // Crear FormData para multipart
    final formData = {
      "accountId": accountId,
      "file": csvContent,
    };
    return apiClient.post("/transactions/import/preview", formData, isMultipart: true);
  }

  Future<Map<String, dynamic>> import(String accountId, String csvContent) async {
    final formData = {
      "accountId": accountId,
      "file": csvContent,
    };
    return apiClient.post("/transactions/import", formData, isMultipart: true);
  }

  Future<Map<String, dynamic>> getImportJob(String jobId) {
    return apiClient.get("/imports/$jobId");
  }
}
