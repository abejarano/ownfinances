import "package:ownfinances/l10n/app_localizations.dart";

class VoiceCaptureCopy {
  final String titleExpense;
  final String titleIncome;
  final String titleTransfer;
  final String buttonType;
  final String statusListening;
  final String statusManual;
  final String statusWaiting;
  final String transcriptPlaceholder;
  final String permissionButton;
  final String chipAmount;
  final String chipAccount;
  final String chipDate;
  final String chipCategory;
  final String promptAmount;
  final String promptAccount;
  final String promptDate;
  final String promptCategory;
  final String amountLabel;
  final String accountLabel;
  final String accountAll;
  final String dateLabel;
  final String dateToday;
  final String dateYesterday;
  final String dateOther;
  final String categoryLabel;
  final String categoryAll;
  final String categoryUncategorized;
  final String confirmTitle;
  final String editButton;
  final String savingLabel;
  final String successLabel;
  final String primaryContinue;
  final String primaryConfirm;
  final String primarySaving;
  final String primaryNew;
  final String secondaryCancel;
  final String secondaryClose;
  final String snackbarMissingAccount;
  final String snackbarMissingDate;
  final String snackbarMissingCategory;
  final String snackbarInvalidAmount;
  final String snackbarSaveError;
  final String snackbarAmountRequired;
  final String searchAccount;
  final String searchCategory;
  final String errorNotUnderstoodType;
  final String errorRepeat;
  final String errorMicPermission;
  final String multipleAccounts;
  final String multipleCategories;
  final String noAccounts;
  final String noCategories;
  final String Function(Object names) accountsListBuilder;
  final String Function(Object names) categoriesListBuilder;
  final String Function(Object summary) confirmPromptBuilder;
  final String editPrompt;
  final String dateSelectPrompt;
  final String conjunction;
  final String Function(
    Object account,
    Object amount,
    Object category,
    Object date,
  ) summaryTemplateBuilder;

  const VoiceCaptureCopy({
    required this.titleExpense,
    required this.titleIncome,
    required this.titleTransfer,
    required this.buttonType,
    required this.statusListening,
    required this.statusManual,
    required this.statusWaiting,
    required this.transcriptPlaceholder,
    required this.permissionButton,
    required this.chipAmount,
    required this.chipAccount,
    required this.chipDate,
    required this.chipCategory,
    required this.promptAmount,
    required this.promptAccount,
    required this.promptDate,
    required this.promptCategory,
    required this.amountLabel,
    required this.accountLabel,
    required this.accountAll,
    required this.dateLabel,
    required this.dateToday,
    required this.dateYesterday,
    required this.dateOther,
    required this.categoryLabel,
    required this.categoryAll,
    required this.categoryUncategorized,
    required this.confirmTitle,
    required this.editButton,
    required this.savingLabel,
    required this.successLabel,
    required this.primaryContinue,
    required this.primaryConfirm,
    required this.primarySaving,
    required this.primaryNew,
    required this.secondaryCancel,
    required this.secondaryClose,
    required this.snackbarMissingAccount,
    required this.snackbarMissingDate,
    required this.snackbarMissingCategory,
    required this.snackbarInvalidAmount,
    required this.snackbarSaveError,
    required this.snackbarAmountRequired,
    required this.searchAccount,
    required this.searchCategory,
    required this.errorNotUnderstoodType,
    required this.errorRepeat,
    required this.errorMicPermission,
    required this.multipleAccounts,
    required this.multipleCategories,
    required this.noAccounts,
    required this.noCategories,
    required this.accountsListBuilder,
    required this.categoriesListBuilder,
    required this.confirmPromptBuilder,
    required this.editPrompt,
    required this.dateSelectPrompt,
    required this.conjunction,
    required this.summaryTemplateBuilder,
  });

  factory VoiceCaptureCopy.fromL10n(AppLocalizations l10n) {
    return VoiceCaptureCopy(
      titleExpense: l10n.voiceTitleExpense,
      titleIncome: l10n.voiceTitleIncome,
      titleTransfer: l10n.voiceTitleTransfer,
      buttonType: l10n.voiceButtonType,
      statusListening: l10n.voiceStatusListening,
      statusManual: l10n.voiceStatusManual,
      statusWaiting: l10n.voiceStatusWaiting,
      transcriptPlaceholder: l10n.voiceTranscriptPlaceholder,
      permissionButton: l10n.voicePermissionButton,
      chipAmount: l10n.voiceChipAmount,
      chipAccount: l10n.voiceChipAccount,
      chipDate: l10n.voiceChipDate,
      chipCategory: l10n.voiceChipCategory,
      promptAmount: l10n.voicePromptAmount,
      promptAccount: l10n.voicePromptAccount,
      promptDate: l10n.voicePromptDate,
      promptCategory: l10n.voicePromptCategory,
      amountLabel: l10n.voiceAmountLabel,
      accountLabel: l10n.voiceAccountLabel,
      accountAll: l10n.voiceAccountAll,
      dateLabel: l10n.voiceDateLabel,
      dateToday: l10n.voiceDateToday,
      dateYesterday: l10n.voiceDateYesterday,
      dateOther: l10n.voiceDateOther,
      categoryLabel: l10n.voiceCategoryLabel,
      categoryAll: l10n.voiceCategoryAll,
      categoryUncategorized: l10n.voiceCategoryUncategorized,
      confirmTitle: l10n.voiceConfirmTitle,
      editButton: l10n.voiceEditButton,
      savingLabel: l10n.voiceSavingLabel,
      successLabel: l10n.voiceSuccessLabel,
      primaryContinue: l10n.voicePrimaryContinue,
      primaryConfirm: l10n.voicePrimaryConfirm,
      primarySaving: l10n.voicePrimarySaving,
      primaryNew: l10n.voicePrimaryNew,
      secondaryCancel: l10n.voiceSecondaryCancel,
      secondaryClose: l10n.voiceSecondaryClose,
      snackbarMissingAccount: l10n.voiceSnackbarMissingAccount,
      snackbarMissingDate: l10n.voiceSnackbarMissingDate,
      snackbarMissingCategory: l10n.voiceSnackbarMissingCategory,
      snackbarInvalidAmount: l10n.voiceSnackbarInvalidAmount,
      snackbarSaveError: l10n.voiceSnackbarSaveError,
      snackbarAmountRequired: l10n.voiceSnackbarAmountRequired,
      searchAccount: l10n.voiceSearchAccount,
      searchCategory: l10n.voiceSearchCategory,
      errorNotUnderstoodType: l10n.voiceErrorNotUnderstoodType,
      errorRepeat: l10n.voiceErrorRepeat,
      errorMicPermission: l10n.voiceErrorMicPermission,
      multipleAccounts: l10n.voiceMultipleAccounts,
      multipleCategories: l10n.voiceMultipleCategories,
      noAccounts: l10n.voiceNoAccounts,
      noCategories: l10n.voiceNoCategories,
      accountsListBuilder: l10n.voiceAccountsListTemplate,
      categoriesListBuilder: l10n.voiceCategoriesListTemplate,
      confirmPromptBuilder: l10n.voiceConfirmPromptTemplate,
      editPrompt: l10n.voiceEditPrompt,
      dateSelectPrompt: l10n.voiceDateSelectPrompt,
      conjunction: l10n.voiceConjunction,
      summaryTemplateBuilder: l10n.voiceSummaryTemplate,
    );
  }

  factory VoiceCaptureCopy.fallbackPt() {
    return const VoiceCaptureCopy(
      titleExpense: "Registrar despesa",
      titleIncome: "Registrar receita",
      titleTransfer: "Registrar transferencia",
      buttonType: "Digitar",
      statusListening: "Estou ouvindo...",
      statusManual: "Modo manual",
      statusWaiting: "Aguardando...",
      transcriptPlaceholder: "Transcricao aparecera aqui",
      permissionButton: "Permitir microfone",
      chipAmount: "Valor",
      chipAccount: "Conta",
      chipDate: "Data",
      chipCategory: "Categoria",
      promptAmount: "Diga o valor",
      promptAccount: "De qual conta sai esse gasto?",
      promptDate: "Foi hoje?",
      promptCategory: "Qual categoria?",
      amountLabel: "Digite o valor",
      accountLabel: "Escolha a conta",
      accountAll: "Ver todas",
      dateLabel: "Quando foi?",
      dateToday: "Hoje",
      dateYesterday: "Ontem",
      dateOther: "Outro dia",
      categoryLabel: "Escolha a categoria",
      categoryAll: "Ver todas",
      categoryUncategorized: "Sem categoria (Outros)",
      confirmTitle: "Confirmacao",
      editButton: "Editar",
      savingLabel: "Salvando...",
      successLabel: "Registrado",
      primaryContinue: "Continuar",
      primaryConfirm: "Confirmar",
      primarySaving: "Salvando",
      primaryNew: "Registrar outro",
      secondaryCancel: "Cancelar",
      secondaryClose: "Fechar",
      snackbarMissingAccount: "Falta escolher conta de saida",
      snackbarMissingDate: "Falta escolher a data",
      snackbarMissingCategory: "Falta escolher categoria",
      snackbarInvalidAmount: "O valor deve ser maior que 0",
      snackbarSaveError: "Erro ao salvar",
      snackbarAmountRequired: "Digite um valor valido",
      searchAccount: "Buscar conta",
      searchCategory: "Buscar categoria",
      errorNotUnderstoodType: "Nao entendi. Pode digitar?",
      errorRepeat: "Nao entendi. Pode repetir?",
      errorMicPermission: "Permissao de microfone negada",
      multipleAccounts: "Encontrei mais de uma conta. Toque para escolher.",
      multipleCategories: "Encontrei mais de uma categoria. Toque para escolher.",
      noAccounts: "Voce ainda nao tem contas cadastradas.",
      noCategories: "Voce ainda nao tem categorias cadastradas.",
      accountsListBuilder: _fallbackAccountsList,
      categoriesListBuilder: _fallbackCategoriesList,
      confirmPromptBuilder: _fallbackConfirmPrompt,
      editPrompt: "Ok. Edite os campos abaixo.",
      dateSelectPrompt: "Ok. Escolha a data abaixo.",
      conjunction: "e",
      summaryTemplateBuilder: _fallbackSummaryTemplate,
    );
  }

  static String _fallbackAccountsList(Object names) =>
      "Suas contas sao: $names.";

  static String _fallbackCategoriesList(Object names) =>
      "As categorias sao: $names.";

  static String _fallbackConfirmPrompt(Object summary) =>
      "$summary Diga confirmado ou cancelar.";

  static String _fallbackSummaryTemplate(
    Object account,
    Object amount,
    Object category,
    Object date,
  ) {
    return "Vou registrar: $amount em $category, da conta $account, $date.";
  }

  String accountsList(String names) => accountsListBuilder(names);

  String categoriesList(String names) => categoriesListBuilder(names);

  String confirmPrompt(String summary) => confirmPromptBuilder(summary);

  String summaryText({
    required String amount,
    required String category,
    required String account,
    required String date,
  }) {
    return summaryTemplateBuilder(account, amount, category, date);
  }
}
