import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/csv_import/application/controllers/csv_import_controller.dart";

class CsvPreviewScreen extends StatefulWidget {
  const CsvPreviewScreen({super.key});

  @override
  State<CsvPreviewScreen> createState() => _CsvPreviewScreenState();
}

class _CsvPreviewScreenState extends State<CsvPreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final importController = context.read<CsvImportController>();
      importController.preview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final importController = context.watch<CsvImportController>();
    final state = importController.state;

    return Scaffold(
      appBar: AppBar(title: const Text("Preview do Import")),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.jobId != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  const Text("Importação iniciada..."),
                  const Text("Aguardando confirmação do servidor."),
                ],
              ),
            )
          : state.preview == null
          ? const Center(child: Text("Carregando preview..."))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.preview!.rows.length,
                    itemBuilder: (context, index) {
                      final row = state.preview!.rows[index];
                      return ListTile(
                        title: Text(row.note ?? "Sem descrição"),
                        subtitle: Text(
                          "${row.date} - ${formatMoney(row.amount)}",
                        ),
                        trailing: Text(row.type),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: PrimaryButton(
                    label: "Confirmar Import",
                    onPressed: () async {
                      await importController.import(context);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
