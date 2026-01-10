import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/csv_import/application/controllers/csv_import_controller.dart";
import "package:ownfinances/features/csv_import/domain/entities/import_job.dart";

class CsvImportResultScreen extends StatefulWidget {
  final String jobId;

  const CsvImportResultScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<CsvImportResultScreen> createState() => _CsvImportResultScreenState();
}

class _CsvImportResultScreenState extends State<CsvImportResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final importController = context.read<CsvImportController>();
      importController.loadImportJob(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final importController = context.watch<CsvImportController>();
    final state = importController.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado do Import"),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.importJob == null
              ? const Center(child: Text("Carregando resultado..."))
              : _buildResult(context, state.importJob!),
    );
  }

  Widget _buildResult(BuildContext context, ImportJob job) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Status: ${job.status}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Importadas: ${job.imported}"),
                  Text("Duplicadas: ${job.duplicates}"),
                  Text("Erros: ${job.errors}"),
                  Text("Total de linhas: ${job.totalRows}"),
                ],
              ),
            ),
          ),
          if (job.errorDetails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              "Erros:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: job.errorDetails.length,
                itemBuilder: (context, index) {
                  final error = job.errorDetails[index];
                  return ListTile(
                    title: Text("Linha ${error.row}"),
                    subtitle: Text(error.error),
                    leading: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
