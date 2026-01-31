import "dart:convert";

import "package:http/http.dart" as http;
import "package:http_parser/http_parser.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";

class CsvImportRemoteDataSource {
  final ApiClient apiClient;

  CsvImportRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> preview(
    String accountId,
    String csvContent,
  ) async {
    // Crear FormData para multipart
    final file = http.MultipartFile.fromBytes(
      "file",
      utf8.encode(csvContent),
      filename: "import.csv",
      contentType: MediaType("text", "csv"),
    );

    final formData = {"accountId": accountId, "file": file};
    final response = await apiClient.post(
      "/transactions/import/preview",
      formData,
      isMultipart: true,
    );
    return response as Map<String, dynamic>;
  }

  Future<void> import(
    String accountId,
    String csvContent,
    int month,
    year,
  ) async {
    final file = http.MultipartFile.fromBytes(
      "file",
      utf8.encode(csvContent),
      filename: "import.csv",
      contentType: MediaType("text", "csv"),
    );

    final formData = {
      "accountId": accountId,
      "file": file,
      "month": month,
      "year": year,
    };

    await apiClient.post("/transactions/import", formData, isMultipart: true);
  }

  Future<Map<String, dynamic>> getImportJob(String jobId) async {
    final response = await apiClient.get("/imports/$jobId");
    return response as Map<String, dynamic>;
  }
}
