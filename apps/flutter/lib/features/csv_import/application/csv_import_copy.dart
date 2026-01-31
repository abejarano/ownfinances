import "package:ownfinances/l10n/app_localizations.dart";

class CsvImportCopy {
  final String errorSelectAccountAndFile;

  const CsvImportCopy({required this.errorSelectAccountAndFile});

  factory CsvImportCopy.fromL10n(AppLocalizations l10n) {
    return CsvImportCopy(
      errorSelectAccountAndFile: l10n.csvImportErrorSelectAccountAndFile,
    );
  }

  factory CsvImportCopy.fallbackPt() {
    return const CsvImportCopy(
      errorSelectAccountAndFile: "Selecione uma conta e carregue o arquivo CSV",
    );
  }
}
