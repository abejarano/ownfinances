import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// The title of the application
  ///
  /// In pt, this message translates to:
  /// **'Desquadra'**
  String get appTitle;

  /// No description provided for @drawerFastAccess.
  ///
  /// In pt, this message translates to:
  /// **'ACESSO RÁPIDO'**
  String get drawerFastAccess;

  /// No description provided for @drawerDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Transações'**
  String get drawerTransactions;

  /// No description provided for @drawerBudgets.
  ///
  /// In pt, this message translates to:
  /// **'Orçamentos'**
  String get drawerBudgets;

  /// No description provided for @drawerMonthSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do mês por categorias'**
  String get drawerMonthSummary;

  /// No description provided for @drawerManagement.
  ///
  /// In pt, this message translates to:
  /// **'GESTÃO'**
  String get drawerManagement;

  /// No description provided for @drawerCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get drawerCategories;

  /// No description provided for @drawerAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get drawerAccounts;

  /// No description provided for @drawerSettings.
  ///
  /// In pt, this message translates to:
  /// **'AJUSTES'**
  String get drawerSettings;

  /// No description provided for @drawerAccount.
  ///
  /// In pt, this message translates to:
  /// **'CONTA'**
  String get drawerAccount;

  /// No description provided for @drawerLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get drawerLogout;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsManageShortcutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar'**
  String get settingsManageShortcutTitle;

  /// No description provided for @settingsManageShortcutDesc.
  ///
  /// In pt, this message translates to:
  /// **'Categorias, Contas, Metas'**
  String get settingsManageShortcutDesc;

  /// No description provided for @settingsManageShortcutButton.
  ///
  /// In pt, this message translates to:
  /// **'Abrir menu'**
  String get settingsManageShortcutButton;

  /// No description provided for @drawerDebts.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas'**
  String get drawerDebts;

  /// No description provided for @drawerGoals.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get drawerGoals;

  /// No description provided for @drawerRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Contas fixas'**
  String get drawerRecurring;

  /// No description provided for @settingsPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get settingsPreferences;

  /// No description provided for @settingsMainCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda principal'**
  String get settingsMainCurrency;

  /// No description provided for @settingsMainCurrencyDesc.
  ///
  /// In pt, this message translates to:
  /// **'O Resumo do mês usa apenas esta moeda. Outras moedas aparecem nas contas (sem conversão).'**
  String get settingsMainCurrencyDesc;

  /// No description provided for @settingsAutomation.
  ///
  /// In pt, this message translates to:
  /// **'Automação'**
  String get settingsAutomation;

  /// No description provided for @settingsAutoGenerate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar automaticamente'**
  String get settingsAutoGenerate;

  /// No description provided for @settingsAutoGenerateDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cria lançamentos de contas fixas ao iniciar o mês (não movimenta dinheiro).'**
  String get settingsAutoGenerateDesc;

  /// No description provided for @settingsAutoGenerateInfo.
  ///
  /// In pt, this message translates to:
  /// **'As transações serão criadas como pendentes na data prevista.'**
  String get settingsAutoGenerateInfo;

  /// No description provided for @settingsVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get settingsVersion;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @currencyOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra'**
  String get currencyOther;

  /// No description provided for @currencyCustomLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código (ex: COP)'**
  String get currencyCustomLabel;

  /// No description provided for @currencyCustomHint.
  ///
  /// In pt, this message translates to:
  /// **'3-5 letras maiúsculas'**
  String get currencyCustomHint;

  /// No description provided for @currencyInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Use 3 a 5 letras (A-Z).'**
  String get currencyInvalid;

  /// No description provided for @settingsAccountSection.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settingsAccountSection;

  /// No description provided for @successSettingsUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Configuração salva com sucesso!'**
  String get successSettingsUpdate;

  /// No description provided for @errorSettingsUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar configuração: {error}'**
  String errorSettingsUpdate(String error);

  /// No description provided for @settingsVersionValue.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String settingsVersionValue(String version);

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'Finanças simples, sem complicação.'**
  String get appTagline;

  /// No description provided for @drawerMainCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda principal: {currency}'**
  String drawerMainCurrency(String currency);

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageSpanish.
  ///
  /// In pt, this message translates to:
  /// **'Espanhol'**
  String get languageSpanish;

  /// No description provided for @onboardingFeature1.
  ///
  /// In pt, this message translates to:
  /// **'• Registrar gasto em 3 toques'**
  String get onboardingFeature1;

  /// No description provided for @onboardingFeature2.
  ///
  /// In pt, this message translates to:
  /// **'• Ver saldo real e planejado'**
  String get onboardingFeature2;

  /// No description provided for @onboardingFeature3.
  ///
  /// In pt, this message translates to:
  /// **'• Tudo em um só lugar, sem jargão'**
  String get onboardingFeature3;

  /// No description provided for @onboardingStartFast.
  ///
  /// In pt, this message translates to:
  /// **'Começar rápido'**
  String get onboardingStartFast;

  /// No description provided for @commonSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get commonSkip;

  /// No description provided for @onboardingWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingDescription.
  ///
  /// In pt, this message translates to:
  /// **'Vamos deixar tudo pronto em menos de 60 segundos.'**
  String get onboardingDescription;

  /// No description provided for @onboardingUseExamples.
  ///
  /// In pt, this message translates to:
  /// **'Quero usar exemplos'**
  String get onboardingUseExamples;

  /// No description provided for @onboardingSkipDescription.
  ///
  /// In pt, this message translates to:
  /// **'Você pode pular e ajustar depois.'**
  String get onboardingSkipDescription;

  /// No description provided for @onboardingCreateAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criaremos uma conta para você registrar gastos.'**
  String get onboardingCreateAccount;

  /// No description provided for @onboardingChooseCreation.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o que quer criar agora.'**
  String get onboardingChooseCreation;

  /// No description provided for @onboardingCreateBudget.
  ///
  /// In pt, this message translates to:
  /// **'Criar orçamento base'**
  String get onboardingCreateBudget;

  /// No description provided for @onboardingCreateBudgetDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você poderá editar depois.'**
  String get onboardingCreateBudgetDesc;

  /// No description provided for @onboardingFirstTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Você já pode registrar seu primeiro gasto.'**
  String get onboardingFirstTransaction;

  /// No description provided for @onboardingAddCards.
  ///
  /// In pt, this message translates to:
  /// **'Adicione seus cartões para controlar faturas.'**
  String get onboardingAddCards;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get commonDelete;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get transactionTypeIncome;

  /// No description provided for @commonActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get commonActive;

  /// No description provided for @recurringTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recorrências'**
  String get recurringTitle;

  /// No description provided for @recurringMyRules.
  ///
  /// In pt, this message translates to:
  /// **'Minhas regras'**
  String get recurringMyRules;

  /// No description provided for @recurringOpenPlanner.
  ///
  /// In pt, this message translates to:
  /// **'Abrir planejador'**
  String get recurringOpenPlanner;

  /// No description provided for @recurringPendingItems.
  ///
  /// In pt, this message translates to:
  /// **'Você tem {count} itens para confirmar.'**
  String recurringPendingItems(int count);

  /// No description provided for @commonView.
  ///
  /// In pt, this message translates to:
  /// **'Ver'**
  String get commonView;

  /// No description provided for @commonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @recurringPlanMonth.
  ///
  /// In pt, this message translates to:
  /// **'Planejar Mês'**
  String get recurringPlanMonth;

  /// No description provided for @recurringGeneratedEntries.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos gerados'**
  String get recurringGeneratedEntries;

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get commonNext;

  /// No description provided for @commonFinish.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar'**
  String get commonFinish;

  /// No description provided for @onboardingMainAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta principal'**
  String get onboardingMainAccount;

  /// No description provided for @accountNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da conta'**
  String get accountNameLabel;

  /// No description provided for @accountTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get accountTypeLabel;

  /// No description provided for @accountTypeBank.
  ///
  /// In pt, this message translates to:
  /// **'Banco'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCash.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get accountTypeCash;

  /// No description provided for @accountTypeWallet.
  ///
  /// In pt, this message translates to:
  /// **'Carteira'**
  String get accountTypeWallet;

  /// No description provided for @onboardingBaseCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias base'**
  String get onboardingBaseCategories;

  /// No description provided for @onboardingAllSet.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pronto'**
  String get onboardingAllSet;

  /// No description provided for @onboardingExamplesCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criamos exemplos básicos para você ajustar depois.'**
  String get onboardingExamplesCreated;

  /// No description provided for @onboardingMinimumCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criamos o mínimo para você começar.'**
  String get onboardingMinimumCreated;

  /// No description provided for @onboardingCreditCards.
  ///
  /// In pt, this message translates to:
  /// **'Cartões de crédito'**
  String get onboardingCreditCards;

  /// No description provided for @onboardingCardName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do cartão'**
  String get onboardingCardName;

  /// No description provided for @onboardingNoCards.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cartão adicionado. Clique em + para adicionar ou Próximo para pular.'**
  String get onboardingNoCards;

  /// No description provided for @recurringAppDescription.
  ///
  /// In pt, this message translates to:
  /// **'O app só registra. Não cobra.'**
  String get recurringAppDescription;

  /// No description provided for @commonNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova'**
  String get commonNew;

  /// No description provided for @recurringInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativas'**
  String get recurringInactive;

  /// No description provided for @recurringNewRule.
  ///
  /// In pt, this message translates to:
  /// **'Nova recorrência'**
  String get recurringNewRule;

  /// No description provided for @recurringEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma recorrência para planejar seu mês em segundos.'**
  String get recurringEmptyState;

  /// No description provided for @recurringFrequencyMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Todo mês dia {day}'**
  String recurringFrequencyMonthly(int day);

  /// No description provided for @recurringFrequencyWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get recurringFrequencyWeekly;

  /// No description provided for @recurringFrequencyYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get recurringFrequencyYearly;

  /// No description provided for @commonComingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get commonComingSoon;

  /// No description provided for @commonPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get commonPause;

  /// No description provided for @commonActivate.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get commonActivate;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir regra?'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Isso não apaga lançamentos já gerados.'**
  String get recurringDeleteDesc;

  /// No description provided for @recurringPlanMonthDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gere os lançamentos do mês a partir das regras.'**
  String get recurringPlanMonthDesc;

  /// No description provided for @recurringPendingConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação pendente'**
  String get recurringPendingConfirmation;

  /// No description provided for @recurringGeneratedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Gerados {count} lançamentos!'**
  String recurringGeneratedSuccess(int count);

  /// No description provided for @recurringGeneratedDialogBody.
  ///
  /// In pt, this message translates to:
  /// **'{count} lançamentos foram criados como pendentes.'**
  String recurringGeneratedDialogBody(int count);

  /// No description provided for @commonStay.
  ///
  /// In pt, this message translates to:
  /// **'Ficar aqui'**
  String get commonStay;

  /// No description provided for @recurringGoToConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Ir para confirmar'**
  String get recurringGoToConfirm;

  /// No description provided for @commonErrorGenerating.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar'**
  String get commonErrorGenerating;

  /// No description provided for @recurringNonePlanned.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma recorrência prevista para este mês.'**
  String get recurringNonePlanned;

  /// No description provided for @recurringGenerateButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar lançamentos ({count})'**
  String recurringGenerateButton(int count);

  /// No description provided for @recurringStatusToGenerate.
  ///
  /// In pt, this message translates to:
  /// **'A gerar'**
  String get recurringStatusToGenerate;

  /// No description provided for @recurringStatusGenerated.
  ///
  /// In pt, this message translates to:
  /// **'Gerados'**
  String get recurringStatusGenerated;

  /// No description provided for @recurringStatusIgnored.
  ///
  /// In pt, this message translates to:
  /// **'Ignorados'**
  String get recurringStatusIgnored;

  /// No description provided for @commonNoDescription.
  ///
  /// In pt, this message translates to:
  /// **'Sem descrição'**
  String get commonNoDescription;

  /// No description provided for @recurringChipGenerated.
  ///
  /// In pt, this message translates to:
  /// **'Gerado'**
  String get recurringChipGenerated;

  /// No description provided for @recurringRestoreTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar (Incluir na geração)'**
  String get recurringRestoreTooltip;

  /// No description provided for @recurringIgnoreTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar (Não gerar)'**
  String get recurringIgnoreTooltip;

  /// No description provided for @recurringMissingGenerated.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {count} lançamentos para gerar'**
  String recurringMissingGenerated(int count);

  /// No description provided for @recurringViewPending.
  ///
  /// In pt, this message translates to:
  /// **'Ver pendentes'**
  String get recurringViewPending;

  /// No description provided for @recurringViewRules.
  ///
  /// In pt, this message translates to:
  /// **'Ver regras'**
  String get recurringViewRules;

  /// No description provided for @recurringNoRulesYet.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem recorrências'**
  String get recurringNoRulesYet;

  /// No description provided for @recurringCreateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeira'**
  String get recurringCreateFirst;

  /// No description provided for @categoriesActive.
  ///
  /// In pt, this message translates to:
  /// **'Categorias ativas'**
  String get categoriesActive;

  /// No description provided for @categoriesDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir categoria?'**
  String get categoriesDeleteTitle;

  /// No description provided for @categoriesDeleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Isso vai excluir a categoria e todas as transações vinculadas. Não dá pra desfazer.'**
  String get categoriesDeleteDesc;

  /// No description provided for @categoriesDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Categoria excluída'**
  String get categoriesDeleted;

  /// No description provided for @categoriesNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova categoria'**
  String get categoriesNew;

  /// No description provided for @categoriesEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar categoria'**
  String get categoriesEdit;

  /// No description provided for @commonPreview.
  ///
  /// In pt, this message translates to:
  /// **'Preview'**
  String get commonPreview;

  /// No description provided for @commonName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get commonName;

  /// No description provided for @categoriesParent.
  ///
  /// In pt, this message translates to:
  /// **'Categoria pai'**
  String get categoriesParent;

  /// No description provided for @categoriesNoParent.
  ///
  /// In pt, this message translates to:
  /// **'Sem pai'**
  String get categoriesNoParent;

  /// No description provided for @categoriesColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get categoriesColor;

  /// No description provided for @categoriesIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone'**
  String get categoriesIcon;

  /// No description provided for @commonNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome obrigatório'**
  String get commonNameRequired;

  /// No description provided for @dashboardMainAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas principais'**
  String get dashboardMainAccounts;

  /// No description provided for @dashboardMainAccountsDesc.
  ///
  /// In pt, this message translates to:
  /// **'As que você mais usa no dia a dia'**
  String get dashboardMainAccountsDesc;

  /// No description provided for @dashboardMainAccountsInfoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas principais'**
  String get dashboardMainAccountsInfoTitle;

  /// No description provided for @dashboardMainAccountsInfoBody.
  ///
  /// In pt, this message translates to:
  /// **'Mostramos as contas com mais movimentos neste mês.'**
  String get dashboardMainAccountsInfoBody;

  /// No description provided for @transactionsManageFixed.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar contas fixas'**
  String get transactionsManageFixed;

  /// No description provided for @transactionsPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transações Pendentes'**
  String get transactionsPendingTitle;

  /// No description provided for @transactionsGroup.
  ///
  /// In pt, this message translates to:
  /// **'Agrupar por:'**
  String get transactionsGroup;

  /// No description provided for @transactionsGroupCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get transactionsGroupCategory;

  /// No description provided for @transactionsGroupRecurrence.
  ///
  /// In pt, this message translates to:
  /// **'Recorrência'**
  String get transactionsGroupRecurrence;

  /// No description provided for @transactionsFilterAllAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Todas as contas'**
  String get transactionsFilterAllAccounts;

  /// No description provided for @transactionsFilterAllCategories.
  ///
  /// In pt, this message translates to:
  /// **'Todas as categorias'**
  String get transactionsFilterAllCategories;

  /// No description provided for @transactionsFilterAllStatus.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get transactionsFilterAllStatus;

  /// No description provided for @transactionsFilterPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get transactionsFilterPending;

  /// No description provided for @transactionsFilterConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmado'**
  String get transactionsFilterConfirmed;

  /// No description provided for @transactionsDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir transação?'**
  String get transactionsDeleteTitle;

  /// No description provided for @transactionsDeleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Essa ação não pode ser desfeita.'**
  String get transactionsDeleteDesc;

  /// No description provided for @transactionsConfirmAll.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar tudo'**
  String get transactionsConfirmAll;

  /// No description provided for @transactionsLabelAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get transactionsLabelAccount;

  /// No description provided for @transactionsLabelCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get transactionsLabelCategory;

  /// No description provided for @transactionsLabelStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get transactionsLabelStatus;

  /// No description provided for @transactionsLabelEntryAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Entrada'**
  String get transactionsLabelEntryAccount;

  /// No description provided for @transactionsLabelCategoryOptional.
  ///
  /// In pt, this message translates to:
  /// **'Categoria (Opcional)'**
  String get transactionsLabelCategoryOptional;

  /// No description provided for @transactionsLabelSource.
  ///
  /// In pt, this message translates to:
  /// **'De (Origem)'**
  String get transactionsLabelSource;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get transactionTypeTransfer;

  /// No description provided for @transactionFormTitleNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Transação'**
  String get transactionFormTitleNew;

  /// No description provided for @transactionFormTitleEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Transação'**
  String get transactionFormTitleEdit;

  /// No description provided for @transactionFormLabelDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get transactionFormLabelDate;

  /// No description provided for @transactionFormLabelNote.
  ///
  /// In pt, this message translates to:
  /// **'Observação'**
  String get transactionFormLabelNote;

  /// No description provided for @transactionFormLabelTags.
  ///
  /// In pt, this message translates to:
  /// **'Tags (separadas por vírgula)'**
  String get transactionFormLabelTags;

  /// No description provided for @transactionFormSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get transactionFormSave;

  /// No description provided for @transactionFormErrorSave.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar'**
  String get transactionFormErrorSave;

  /// No description provided for @transactionFormSuccessSave.
  ///
  /// In pt, this message translates to:
  /// **'Transação salva!'**
  String get transactionFormSuccessSave;

  /// No description provided for @transactionFormConfirmDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir transação?'**
  String get transactionFormConfirmDelete;

  /// No description provided for @transactionFormConfirmConversion.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar conversão'**
  String get transactionFormConfirmConversion;

  /// No description provided for @transactionFormLabelYouSend.
  ///
  /// In pt, this message translates to:
  /// **'Você envia:'**
  String get transactionFormLabelYouSend;

  /// No description provided for @transactionFormLabelYouReceive.
  ///
  /// In pt, this message translates to:
  /// **'Você recebe:'**
  String get transactionFormLabelYouReceive;

  /// No description provided for @transactionFormEffectiveRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa efetiva: 1 {fromCurrency} ≈ {toCurrency} {rate}'**
  String transactionFormEffectiveRate(
    String fromCurrency,
    String toCurrency,
    String rate,
  );

  /// No description provided for @transactionFormChangeAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alterar contas?'**
  String get transactionFormChangeAccountTitle;

  /// No description provided for @transactionFormChangeAccountDesc.
  ///
  /// In pt, this message translates to:
  /// **'Isso pode mudar a moeda e limpar os valores informados.'**
  String get transactionFormChangeAccountDesc;

  /// No description provided for @transactionFormChangeAccountConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Alterar e limpar'**
  String get transactionFormChangeAccountConfirm;

  /// No description provided for @transactionFormTypeExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get transactionFormTypeExpense;

  /// No description provided for @transactionFormTypeIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get transactionFormTypeIncome;

  /// No description provided for @transactionFormTypeTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transf.'**
  String get transactionFormTypeTransfer;

  /// No description provided for @transactionFormMsgRecurringError.
  ///
  /// In pt, this message translates to:
  /// **'Transação salva, mas não foi possível criar a recorrência.'**
  String get transactionFormMsgRecurringError;

  /// No description provided for @transactionFormMsgRecurringSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Transação salva e recorrência criada!'**
  String get transactionFormMsgRecurringSuccess;

  /// No description provided for @transactionFormRecurringConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar conta fixa'**
  String get transactionFormRecurringConfirm;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @accountsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get accountsTitle;

  /// No description provided for @accountsWarningCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moedas precisam de revisão'**
  String get accountsWarningCurrency;

  /// No description provided for @accountsWarningCurrencyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Algumas contas estão com moeda inválida e podem causar valores errados no dashboard.'**
  String get accountsWarningCurrencyDesc;

  /// No description provided for @accountsFixCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Corrigir agora'**
  String get accountsFixCurrency;

  /// No description provided for @accountsActive.
  ///
  /// In pt, this message translates to:
  /// **'Contas ativas'**
  String get accountsActive;

  /// No description provided for @accountsCardsSection.
  ///
  /// In pt, this message translates to:
  /// **'Cartões'**
  String get accountsCardsSection;

  /// No description provided for @accountsCardChip.
  ///
  /// In pt, this message translates to:
  /// **'CARTÃO'**
  String get accountsCardChip;

  /// No description provided for @accountsCardCurrentBill.
  ///
  /// In pt, this message translates to:
  /// **'Fatura atual'**
  String get accountsCardCurrentBill;

  /// No description provided for @accountsCardViewDebts.
  ///
  /// In pt, this message translates to:
  /// **'Ver em Dívidas'**
  String get accountsCardViewDebts;

  /// No description provided for @accountsDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta?'**
  String get accountsDeleteTitle;

  /// No description provided for @accountsDeleteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Isso vai excluir a conta e todas as transações vinculadas. Não dá pra desfazer.'**
  String get accountsDeleteDesc;

  /// No description provided for @accountsDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Conta excluída'**
  String get accountsDeleted;

  /// No description provided for @accountsNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta'**
  String get accountsNew;

  /// No description provided for @accountsEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar conta'**
  String get accountsEdit;

  /// No description provided for @accountsTypeMoney.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get accountsTypeMoney;

  /// No description provided for @accountsTypeBank.
  ///
  /// In pt, this message translates to:
  /// **'Banco'**
  String get accountsTypeBank;

  /// No description provided for @accountsTypeWallet.
  ///
  /// In pt, this message translates to:
  /// **'Carteira'**
  String get accountsTypeWallet;

  /// No description provided for @accountsTypeBroker.
  ///
  /// In pt, this message translates to:
  /// **'Investimentos'**
  String get accountsTypeBroker;

  /// No description provided for @accountsTypeCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get accountsTypeCard;

  /// No description provided for @accountsLabelBank.
  ///
  /// In pt, this message translates to:
  /// **'Banco'**
  String get accountsLabelBank;

  /// No description provided for @accountsLabelCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get accountsLabelCurrency;

  /// No description provided for @accountsLabelCurrencyCode.
  ///
  /// In pt, this message translates to:
  /// **'Código da moeda'**
  String get accountsLabelCurrencyCode;

  /// No description provided for @accountsHintCurrencyCode.
  ///
  /// In pt, this message translates to:
  /// **'Ex: COP, ARS'**
  String get accountsHintCurrencyCode;

  /// No description provided for @accountsHelperCurrencyCode.
  ///
  /// In pt, this message translates to:
  /// **'Use 3-5 letras em maiúsculo. Ex: COP.'**
  String get accountsHelperCurrencyCode;

  /// No description provided for @accountsErrorCurrencyInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Use 3-5 letras (ex: COP).'**
  String get accountsErrorCurrencyInvalid;

  /// No description provided for @budgetsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamentos'**
  String get budgetsTitle;

  /// No description provided for @budgetsTabGoals.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get budgetsTabGoals;

  /// No description provided for @budgetsTabFixed.
  ///
  /// In pt, this message translates to:
  /// **'Contas fixas'**
  String get budgetsTabFixed;

  /// No description provided for @budgetsMonthTitle.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento do mês'**
  String get budgetsMonthTitle;

  /// No description provided for @budgetsPlanPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Plano do período'**
  String get budgetsPlanPeriod;

  /// No description provided for @budgetsLabelPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Planejado'**
  String get budgetsLabelPlanned;

  /// No description provided for @budgetsLabelActual.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get budgetsLabelActual;

  /// No description provided for @budgetsLabelRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Restante'**
  String get budgetsLabelRemaining;

  /// No description provided for @budgetsHeaderIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receitas planejadas'**
  String get budgetsHeaderIncome;

  /// No description provided for @budgetsHeaderExpense.
  ///
  /// In pt, this message translates to:
  /// **'Gastos planejados'**
  String get budgetsHeaderExpense;

  /// No description provided for @budgetsHeaderBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo planejado'**
  String get budgetsHeaderBalance;

  /// No description provided for @budgetsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem orçamento para este mês'**
  String get budgetsEmptyTitle;

  /// No description provided for @budgetsEmptyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crie um orçamento para planejar seus gastos por categoria.'**
  String get budgetsEmptyDesc;

  /// No description provided for @budgetsCreateButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar orçamento deste mês'**
  String get budgetsCreateButton;

  /// No description provided for @budgetsActionRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover do mês'**
  String get budgetsActionRemove;

  /// No description provided for @budgetsSuccessRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Categoria removida do orçamento deste mês'**
  String get budgetsSuccessRemoved;

  /// No description provided for @budgetsRemoveCategory.
  ///
  /// In pt, this message translates to:
  /// **'Remover do mês'**
  String get budgetsRemoveCategory;

  /// No description provided for @budgetsSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar orçamento'**
  String get budgetsSaveButton;

  /// No description provided for @budgetsSuccessSaved.
  ///
  /// In pt, this message translates to:
  /// **'Orçamento salvo!'**
  String get budgetsSuccessSaved;

  /// No description provided for @budgetsMonthSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do mês'**
  String get budgetsMonthSummaryTitle;

  /// No description provided for @budgetsMonthSummaryPlannedCategories.
  ///
  /// In pt, this message translates to:
  /// **'Gastos planejados (categorias)'**
  String get budgetsMonthSummaryPlannedCategories;

  /// No description provided for @budgetsMonthSummaryPlannedDebts.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos de dívidas planejados'**
  String get budgetsMonthSummaryPlannedDebts;

  /// No description provided for @budgetsMonthSummaryTotalOutflow.
  ///
  /// In pt, this message translates to:
  /// **'Total de saídas planejadas'**
  String get budgetsMonthSummaryTotalOutflow;

  /// No description provided for @budgetsMonthSummaryOtherCurrencies.
  ///
  /// In pt, this message translates to:
  /// **'Outras moedas (sem conversão)'**
  String get budgetsMonthSummaryOtherCurrencies;

  /// No description provided for @budgetsDebtPlannedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas (pagos planejados)'**
  String get budgetsDebtPlannedTitle;

  /// No description provided for @budgetsDebtPlannedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Reserve quanto você vai pagar este mês. Não é um gasto novo.'**
  String get budgetsDebtPlannedSubtitle;

  /// No description provided for @budgetsDebtPaymentNote.
  ///
  /// In pt, this message translates to:
  /// **'Pagar dívida não é um gasto novo. É pagar algo que você já deve.'**
  String get budgetsDebtPaymentNote;

  /// No description provided for @budgetsDebtPayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vou pagar'**
  String get budgetsDebtPayLabel;

  /// No description provided for @budgetsDebtOweLabel.
  ///
  /// In pt, this message translates to:
  /// **'Devo'**
  String get budgetsDebtOweLabel;

  /// No description provided for @budgetsDebtPaidPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Pago: {paid} / {planned} planejado'**
  String budgetsDebtPaidPlanned(Object paid, Object planned);

  /// No description provided for @budgetsDebtActionZeroAll.
  ///
  /// In pt, this message translates to:
  /// **'Zerar tudo'**
  String get budgetsDebtActionZeroAll;

  /// No description provided for @budgetsDebtActionSuggest.
  ///
  /// In pt, this message translates to:
  /// **'Sugerir pagamentos'**
  String get budgetsDebtActionSuggest;

  /// No description provided for @budgetsDebtOverpaid.
  ///
  /// In pt, this message translates to:
  /// **'Você pagou {amount} a mais que o planejado.'**
  String budgetsDebtOverpaid(Object amount);

  /// No description provided for @budgetsDebtRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount} para seu plano.'**
  String budgetsDebtRemaining(Object amount);

  /// No description provided for @budgetsDebtEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem dívidas ativas.'**
  String get budgetsDebtEmptyState;

  /// No description provided for @budgetsDebtMinimumWarning.
  ///
  /// In pt, this message translates to:
  /// **'Seu plano está abaixo do mínimo.'**
  String get budgetsDebtMinimumWarning;

  /// No description provided for @budgetsDebtTotalPlannedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total pagamentos planejados ({currency})'**
  String budgetsDebtTotalPlannedLabel(Object currency);

  /// No description provided for @budgetsCategoriesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gastos por categoria'**
  String get budgetsCategoriesTitle;

  /// No description provided for @accountsSuccessCurrencyFixed.
  ///
  /// In pt, this message translates to:
  /// **'Moedas corrigidas com sucesso!'**
  String get accountsSuccessCurrencyFixed;

  /// No description provided for @goalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get goalsTitle;

  /// No description provided for @goalsMyGoals.
  ///
  /// In pt, this message translates to:
  /// **'Suas metas'**
  String get goalsMyGoals;

  /// No description provided for @goalsNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova meta'**
  String get goalsNew;

  /// No description provided for @goalsEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar meta'**
  String get goalsEdit;

  /// No description provided for @goalsCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar meta'**
  String get goalsCreate;

  /// No description provided for @goalsNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da meta'**
  String get goalsNameLabel;

  /// No description provided for @goalsNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Fundo de emergência'**
  String get goalsNameHint;

  /// No description provided for @goalsTargetAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor alvo'**
  String get goalsTargetAmount;

  /// No description provided for @goalsDetailsOptional.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes (opcional)'**
  String get goalsDetailsOptional;

  /// No description provided for @goalsTargetDate.
  ///
  /// In pt, this message translates to:
  /// **'Data alvo (opcional)'**
  String get goalsTargetDate;

  /// No description provided for @goalsNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get goalsNoDate;

  /// No description provided for @goalsSuggestedMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Sugerido: {amount} por mês'**
  String goalsSuggestedMonthly(Object amount);

  /// No description provided for @goalsMonthlyContribution.
  ///
  /// In pt, this message translates to:
  /// **'Aporte mensal (opcional)'**
  String get goalsMonthlyContribution;

  /// No description provided for @goalsLinkedAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta vinculada (opcional)'**
  String get goalsLinkedAccount;

  /// No description provided for @goalsContributionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar aporte'**
  String get goalsContributionTitle;

  /// No description provided for @goalsContributionValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get goalsContributionValue;

  /// No description provided for @goalsNoAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem contas ativas.'**
  String get goalsNoAccounts;

  /// No description provided for @goalsDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get goalsDate;

  /// No description provided for @goalsNoteOptional.
  ///
  /// In pt, this message translates to:
  /// **'Nota (opcional)'**
  String get goalsNoteOptional;

  /// No description provided for @goalsErrorName.
  ///
  /// In pt, this message translates to:
  /// **'Falta o nome'**
  String get goalsErrorName;

  /// No description provided for @goalsErrorAmount.
  ///
  /// In pt, this message translates to:
  /// **'O valor deve ser maior que 0'**
  String get goalsErrorAmount;

  /// No description provided for @goalsQuickAddConfigError.
  ///
  /// In pt, this message translates to:
  /// **'Configure um aporte mensal para usar aporte rápido'**
  String get goalsQuickAddConfigError;

  /// No description provided for @goalsAccountConfigError.
  ///
  /// In pt, this message translates to:
  /// **'Configure uma conta para usar aporte rápido'**
  String get goalsAccountConfigError;

  /// No description provided for @goalsContributionSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Aporte de {amount} registrado'**
  String goalsContributionSuccess(Object amount);

  /// No description provided for @goalsProjectionIdeal.
  ///
  /// In pt, this message translates to:
  /// **'Se guardar {amount}/mês, chega em {date}.'**
  String goalsProjectionIdeal(Object amount, Object date);

  /// No description provided for @goalsProjectionOnTrack.
  ///
  /// In pt, this message translates to:
  /// **'Guardando {amount}/mês, chega em {date}.'**
  String goalsProjectionOnTrack(Object amount, Object date);

  /// No description provided for @goalsProjectionOnTrackNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Guardando {amount}/mês'**
  String goalsProjectionOnTrackNoDate(Object amount);

  /// No description provided for @goalsProjectionOffTrack.
  ///
  /// In pt, this message translates to:
  /// **'Para chegar em {date}, precisa guardar {amount}/mês.'**
  String goalsProjectionOffTrack(Object amount, Object date);

  /// No description provided for @goalsProjectionDateOnly.
  ///
  /// In pt, this message translates to:
  /// **'Meta {date}'**
  String goalsProjectionDateOnly(Object date);

  /// No description provided for @goalsRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Restante {amount}'**
  String goalsRemaining(Object amount);

  /// No description provided for @goalsQuickAdd.
  ///
  /// In pt, this message translates to:
  /// **'Aporte rápido'**
  String get goalsQuickAdd;

  /// No description provided for @goalsCustomize.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar'**
  String get goalsCustomize;

  /// No description provided for @goalsViewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get goalsViewDetails;

  /// No description provided for @debtsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas'**
  String get debtsTitle;

  /// No description provided for @debtsActiveLiabilities.
  ///
  /// In pt, this message translates to:
  /// **'Passivos ativos'**
  String get debtsActiveLiabilities;

  /// No description provided for @debtsNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova dívida'**
  String get debtsNew;

  /// No description provided for @debtsEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar dívida'**
  String get debtsEdit;

  /// No description provided for @debtsName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get debtsName;

  /// No description provided for @debtsType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get debtsType;

  /// No description provided for @debtsTypeCreditCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de Crédito'**
  String get debtsTypeCreditCard;

  /// No description provided for @debtsTypeLoan.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimo'**
  String get debtsTypeLoan;

  /// No description provided for @debtsTypeOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get debtsTypeOther;

  /// No description provided for @debtsNoCreditCardAccount.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem contas do tipo \'Cartão de Crédito\'.'**
  String get debtsNoCreditCardAccount;

  /// No description provided for @debtsCreateCardAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta Cartão agora'**
  String get debtsCreateCardAccount;

  /// No description provided for @debtsLinkedAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta do cartão (Onde caem as compras)'**
  String get debtsLinkedAccount;

  /// No description provided for @debtsInitialBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial'**
  String get debtsInitialBalance;

  /// No description provided for @debtsInitialBalanceCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Saldo atual (opcional)'**
  String get debtsInitialBalanceCurrent;

  /// No description provided for @debtsInitialBalanceHelper.
  ///
  /// In pt, this message translates to:
  /// **'Se você já tem saldo a pagar neste cartão hoje, informe aqui. Se não, deixe 0.'**
  String get debtsInitialBalanceHelper;

  /// No description provided for @debtsInitialBalanceWarning.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial não pode ser alterado. Ajuste registrando uma compra/pagamento.'**
  String get debtsInitialBalanceWarning;

  /// No description provided for @debtsNoPayingAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem contas bancárias/dinheiro para pagar a fatura.'**
  String get debtsNoPayingAccount;

  /// No description provided for @debtsPayingAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta pagadora padrão (Opcional)'**
  String get debtsPayingAccount;

  /// No description provided for @debtsPayingAccountHelper.
  ///
  /// In pt, this message translates to:
  /// **'Conta sugerida quando você registrar o pagamento da fatura.'**
  String get debtsPayingAccountHelper;

  /// No description provided for @debtsDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Dia de vencimento'**
  String get debtsDueDate;

  /// No description provided for @debtsDueDateHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 10'**
  String get debtsDueDateHint;

  /// No description provided for @debtsDueDateError.
  ///
  /// In pt, this message translates to:
  /// **'Entre 1 e 31'**
  String get debtsDueDateError;

  /// No description provided for @debtsAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Avançado (opcional)'**
  String get debtsAdvanced;

  /// No description provided for @debtsMinimumPayment.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo a pagar'**
  String get debtsMinimumPayment;

  /// No description provided for @debtsInterestRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa anual (%)'**
  String get debtsInterestRate;

  /// No description provided for @debtsErrorSelectAccount.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a conta do cartão'**
  String get debtsErrorSelectAccount;

  /// No description provided for @debtsErrorNoLinkedAccount.
  ///
  /// In pt, this message translates to:
  /// **'Esta dívida não tem conta vinculada. Edite a dívida para vincular uma conta do tipo Cartão.'**
  String get debtsErrorNoLinkedAccount;

  /// No description provided for @debtsQuickAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta rápida'**
  String get debtsQuickAccountTitle;

  /// No description provided for @debtsQuickAccountName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da conta'**
  String get debtsQuickAccountName;

  /// No description provided for @debtsDueDayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vence dia {day}'**
  String debtsDueDayLabel(Object day);

  /// No description provided for @debtsCurrentBill.
  ///
  /// In pt, this message translates to:
  /// **'Fatura atual:'**
  String get debtsCurrentBill;

  /// No description provided for @debtsAvailableCredit.
  ///
  /// In pt, this message translates to:
  /// **'Crédito disponível:'**
  String get debtsAvailableCredit;

  /// No description provided for @debtsAllPaid.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pago 🎉'**
  String get debtsAllPaid;

  /// No description provided for @debtsActionCharge.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Compra'**
  String get debtsActionCharge;

  /// No description provided for @debtsActionPay.
  ///
  /// In pt, this message translates to:
  /// **'Pagar fatura'**
  String get debtsActionPay;

  /// No description provided for @debtsDialogPaidTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pago ✅'**
  String get debtsDialogPaidTitle;

  /// No description provided for @debtsDialogPaidBody.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem saldo a pagar neste cartão.'**
  String get debtsDialogPaidBody;

  /// No description provided for @debtsDialogPaidAction.
  ///
  /// In pt, this message translates to:
  /// **'Pagar mesmo assim'**
  String get debtsDialogPaidAction;

  /// No description provided for @debtsDialogLinkTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conta não vinculada'**
  String get debtsDialogLinkTitle;

  /// No description provided for @debtsDialogLinkBody.
  ///
  /// In pt, this message translates to:
  /// **'Para pagar a fatura, você precisa vincular uma conta do tipo \'Cartão de Crédito\' a esta dívida.'**
  String get debtsDialogLinkBody;

  /// No description provided for @debtsDialogLinkAction.
  ///
  /// In pt, this message translates to:
  /// **'Vincular agora'**
  String get debtsDialogLinkAction;

  /// No description provided for @monthSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo geral do mês'**
  String get monthSummaryTitle;

  /// No description provided for @monthSummaryTabCategories.
  ///
  /// In pt, this message translates to:
  /// **'Por categoria'**
  String get monthSummaryTabCategories;

  /// No description provided for @monthSummaryTabAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Por conta'**
  String get monthSummaryTabAccounts;

  /// No description provided for @monthSummaryTabOtherCurrencies.
  ///
  /// In pt, this message translates to:
  /// **'Outras moedas'**
  String get monthSummaryTabOtherCurrencies;

  /// No description provided for @monthSummaryHeaderHelper.
  ///
  /// In pt, this message translates to:
  /// **'Sem conversão automática. Valores por moeda.'**
  String get monthSummaryHeaderHelper;

  /// No description provided for @monthSummaryEmptyPrimary.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos em {currency} neste mês.'**
  String monthSummaryEmptyPrimary(Object currency);

  /// No description provided for @monthSummarySeeOtherCurrencies.
  ///
  /// In pt, this message translates to:
  /// **'Veja em Outras moedas'**
  String get monthSummarySeeOtherCurrencies;

  /// No description provided for @monthSummaryTotalSpent.
  ///
  /// In pt, this message translates to:
  /// **'Total gastos ({currency}):'**
  String monthSummaryTotalSpent(Object currency);

  /// No description provided for @monthSummaryOtherCurrencies.
  ///
  /// In pt, this message translates to:
  /// **'Outras moedas (sem conversão):'**
  String get monthSummaryOtherCurrencies;

  /// No description provided for @monthSummaryNoAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta encontrada'**
  String get monthSummaryNoAccounts;

  /// No description provided for @monthSummaryIncome.
  ///
  /// In pt, this message translates to:
  /// **'Entradas'**
  String get monthSummaryIncome;

  /// No description provided for @monthSummaryPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos'**
  String get monthSummaryPayments;

  /// No description provided for @monthSummaryExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Saídas'**
  String get monthSummaryExpenses;

  /// No description provided for @monthSummaryPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get monthSummaryPurchases;

  /// No description provided for @monthSummaryNetMonth.
  ///
  /// In pt, this message translates to:
  /// **'Variação no mês'**
  String get monthSummaryNetMonth;

  /// No description provided for @monthSummaryBalanceMonth.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do mês'**
  String get monthSummaryBalanceMonth;

  /// No description provided for @monthSummaryViewInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Ver fatura/histórico'**
  String get monthSummaryViewInvoice;

  /// No description provided for @monthSummaryViewTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Ver transações'**
  String get monthSummaryViewTransactions;

  /// No description provided for @monthSummaryNoOtherCurrencies.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma outra moeda movimentada'**
  String get monthSummaryNoOtherCurrencies;

  /// No description provided for @monthSummaryOtherCurrenciesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Os valores abaixo não são convertidos para a moeda principal.'**
  String get monthSummaryOtherCurrenciesSubtitle;

  /// No description provided for @monthSummaryNet.
  ///
  /// In pt, this message translates to:
  /// **'Líquido'**
  String get monthSummaryNet;

  /// No description provided for @authLoginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authLoginTitle;

  /// No description provided for @authContinueGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com Apple'**
  String get authContinueApple;

  /// No description provided for @authOr.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get authOr;

  /// No description provided for @authLoginEmail.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com e-mail'**
  String get authLoginEmail;

  /// No description provided for @authEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get authPasswordLabel;

  /// No description provided for @authButtonLogin.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authButtonLogin;

  /// No description provided for @authButtonRegister.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get authButtonRegister;

  /// No description provided for @authLoadingLogin.
  ///
  /// In pt, this message translates to:
  /// **'Entrando...'**
  String get authLoadingLogin;

  /// No description provided for @authLoadingRegister.
  ///
  /// In pt, this message translates to:
  /// **'Criando conta...'**
  String get authLoadingRegister;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Já tenho conta'**
  String get authSwitchToLogin;

  /// No description provided for @authSwitchToRegister.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova conta'**
  String get authSwitchToRegister;

  /// No description provided for @authDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Usamos seu login apenas para acessar sua conta.'**
  String get authDisclaimer;

  /// No description provided for @authRegisterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterQuick.
  ///
  /// In pt, this message translates to:
  /// **'Registro rápido'**
  String get authRegisterQuick;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Só email e senha. Em menos de 30s.'**
  String get authRegisterSubtitle;

  /// No description provided for @transactionFormErrorCreate.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar a transação.'**
  String get transactionFormErrorCreate;

  /// No description provided for @transactionFormSuccessUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Transação atualizada com sucesso!'**
  String get transactionFormSuccessUpdate;

  /// No description provided for @transactionFormErrorUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {error}'**
  String transactionFormErrorUpdate(String error);

  /// No description provided for @transactionFormLabelCardPurchase.
  ///
  /// In pt, this message translates to:
  /// **'Compra no cartão'**
  String get transactionFormLabelCardPurchase;

  /// No description provided for @transactionFormLabelSource.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Saída'**
  String get transactionFormLabelSource;

  /// No description provided for @transactionsLabelDestination.
  ///
  /// In pt, this message translates to:
  /// **'Para (Destino)'**
  String get transactionsLabelDestination;

  /// No description provided for @transactionsActionImportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Importar CSV'**
  String get transactionsActionImportCsv;

  /// No description provided for @transactionFormRecurringError.
  ///
  /// In pt, this message translates to:
  /// **'Transação salva, mas não foi possível criar a recorrência.'**
  String get transactionFormRecurringError;

  /// No description provided for @transactionFormRecurringSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Transação salva e recorrência criada!'**
  String get transactionFormRecurringSuccess;

  /// No description provided for @recurringSummaryDay.
  ///
  /// In pt, this message translates to:
  /// **'Todo dia {day}'**
  String recurringSummaryDay(Object day);

  /// No description provided for @navDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Transações'**
  String get navTransactions;

  /// No description provided for @navBudgets.
  ///
  /// In pt, this message translates to:
  /// **'Orçamentos'**
  String get navBudgets;

  /// No description provided for @navSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @dashboardShortcutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do mês por categorias'**
  String get dashboardShortcutTitle;

  /// No description provided for @dashboardShortcutDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sem conversão automática.\nToque para ver gastos por moeda e categoria.'**
  String get dashboardShortcutDesc;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ações rápidas'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardQuickActionExpense.
  ///
  /// In pt, this message translates to:
  /// **'Gasto'**
  String get dashboardQuickActionExpense;

  /// No description provided for @dashboardQuickActionIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get dashboardQuickActionIncome;

  /// No description provided for @dashboardQuickActionTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferir'**
  String get dashboardQuickActionTransfer;

  /// No description provided for @dashboardQuickActionFixed.
  ///
  /// In pt, this message translates to:
  /// **'Contas fixas'**
  String get dashboardQuickActionFixed;

  /// No description provided for @cardLabelCredit.
  ///
  /// In pt, this message translates to:
  /// **'CARTÃO'**
  String get cardLabelCredit;

  /// No description provided for @cardLabelBalancePay.
  ///
  /// In pt, this message translates to:
  /// **'Saldo a pagar'**
  String get cardLabelBalancePay;

  /// No description provided for @cardLabelDueDay.
  ///
  /// In pt, this message translates to:
  /// **'Vence dia {day}'**
  String cardLabelDueDay(Object day);

  /// No description provided for @cardLabelPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos'**
  String get cardLabelPayments;

  /// No description provided for @cardLabelPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get cardLabelPurchases;

  /// No description provided for @cardLabelIncomes.
  ///
  /// In pt, this message translates to:
  /// **'Entradas'**
  String get cardLabelIncomes;

  /// No description provided for @cardLabelExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Saídas'**
  String get cardLabelExpenses;

  /// No description provided for @cardLabelMonthBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do mês'**
  String get cardLabelMonthBalance;

  /// No description provided for @cardLabelNoMovements.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos este mês'**
  String get cardLabelNoMovements;

  /// No description provided for @cardActionView.
  ///
  /// In pt, this message translates to:
  /// **'Ver transações'**
  String get cardActionView;

  /// No description provided for @debtsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas'**
  String get debtsSectionTitle;

  /// No description provided for @debtsEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não cadastrou dívidas.'**
  String get debtsEmptyState;

  /// No description provided for @debtsActionAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar dívida'**
  String get debtsActionAdd;

  /// No description provided for @debtsActionViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver dívidas'**
  String get debtsActionViewAll;

  /// No description provided for @debtsPaidMonth.
  ///
  /// In pt, this message translates to:
  /// **'Pago este mês: '**
  String get debtsPaidMonth;

  /// No description provided for @debtsTotalToPay.
  ///
  /// In pt, this message translates to:
  /// **'Total a pagar'**
  String get debtsTotalToPay;

  /// No description provided for @debtsNextDue.
  ///
  /// In pt, this message translates to:
  /// **'Próximo: {date} — {name}'**
  String debtsNextDue(Object date, Object name);

  /// No description provided for @debtsPaymentDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Registra um pagamento (não é cobrança automática).'**
  String get debtsPaymentDisclaimer;

  /// No description provided for @commonUnderstood.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get commonUnderstood;

  /// No description provided for @dashboardOtherAccountsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Outras contas'**
  String get dashboardOtherAccountsTitle;

  /// No description provided for @dashboardOtherAccountsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Contas menos usadas ou sem movimentos no mês'**
  String get dashboardOtherAccountsDesc;

  /// No description provided for @dashboardOtherAccountsNoMovements.
  ///
  /// In pt, this message translates to:
  /// **'Sem movimentos neste mês'**
  String get dashboardOtherAccountsNoMovements;

  /// No description provided for @dashboardOtherAccountsMonthBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do mês: {amount}'**
  String dashboardOtherAccountsMonthBalance(Object amount);

  /// No description provided for @dashboardOtherAccountsViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas ({count})'**
  String dashboardOtherAccountsViewAll(Object count);

  /// No description provided for @transactionFormLabelInvoicePayment.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento de fatura'**
  String get transactionFormLabelInvoicePayment;

  /// No description provided for @transactionFormLabelCardSourceError.
  ///
  /// In pt, this message translates to:
  /// **'Cartão não pode ser conta de origem. Use sua conta bancária.'**
  String get transactionFormLabelCardSourceError;

  /// No description provided for @transactionFormLabelDebtWarning.
  ///
  /// In pt, this message translates to:
  /// **'Isso aumenta sua dívida. Não sai do banco agora.'**
  String get transactionFormLabelDebtWarning;

  /// No description provided for @transactionFormLabelPaymentValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor do pagamento'**
  String get transactionFormLabelPaymentValue;

  /// No description provided for @transactionFormHelperPayment.
  ///
  /// In pt, this message translates to:
  /// **'Sai do banco e abate na fatura.'**
  String get transactionFormHelperPayment;

  /// No description provided for @transactionFormLabelTransferValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get transactionFormLabelTransferValue;

  /// No description provided for @transactionFormHelperTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Valor que sai da origem e entra no destino.'**
  String get transactionFormHelperTransfer;

  /// No description provided for @transactionFormLabelSentValue.
  ///
  /// In pt, this message translates to:
  /// **'Você envia ({currency})'**
  String transactionFormLabelSentValue(String currency);

  /// No description provided for @transactionFormHelperSent.
  ///
  /// In pt, this message translates to:
  /// **'Valor que sai da conta de origem.'**
  String get transactionFormHelperSent;

  /// No description provided for @transactionFormLabelReceivedValue.
  ///
  /// In pt, this message translates to:
  /// **'Você recebe ({currency})'**
  String transactionFormLabelReceivedValue(String currency);

  /// No description provided for @transactionFormHelperReceived.
  ///
  /// In pt, this message translates to:
  /// **'Valor que entra na conta de destino.'**
  String get transactionFormHelperReceived;

  /// No description provided for @transactionFormLabelSelectSourceDest.
  ///
  /// In pt, this message translates to:
  /// **'Selecione Origem e Destino'**
  String get transactionFormLabelSelectSourceDest;

  /// No description provided for @transactionFormHelperSelectSourceDest.
  ///
  /// In pt, this message translates to:
  /// **'Escolha as contas para liberar o valor.'**
  String get transactionFormHelperSelectSourceDest;

  /// No description provided for @transactionFormLabelAlreadyCleared.
  ///
  /// In pt, this message translates to:
  /// **'Já entrou no saldo?'**
  String get transactionFormLabelAlreadyCleared;

  /// No description provided for @transactionFormStatusCleared.
  ///
  /// In pt, this message translates to:
  /// **'Confirmada'**
  String get transactionFormStatusCleared;

  /// No description provided for @transactionFormStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get transactionFormStatusPending;

  /// No description provided for @transactionFormHelperStatus.
  ///
  /// In pt, this message translates to:
  /// **'Se estiver pendente, pode mudar depois.'**
  String get transactionFormHelperStatus;

  /// No description provided for @transactionFormLabelMoreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get transactionFormLabelMoreOptions;

  /// No description provided for @transactionFormLabelMoreOptionsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nota, Tags, Recorrência'**
  String get transactionFormLabelMoreOptionsSubtitle;

  /// No description provided for @transactionFormLabelMoreOptionsRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Recorrente'**
  String get transactionFormLabelMoreOptionsRecurring;

  /// No description provided for @transactionFormLabelRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Repetir automaticamente'**
  String get transactionFormLabelRepeat;

  /// No description provided for @transactionFormHelperRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Cria uma conta fixa para você não esquecer.'**
  String get transactionFormHelperRepeat;

  /// No description provided for @transactionFormLabelFrequencyMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get transactionFormLabelFrequencyMonthly;

  /// No description provided for @transactionFormLabelFrequencyWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get transactionFormLabelFrequencyWeekly;

  /// No description provided for @transactionFormActionManageFixed.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar contas fixas'**
  String get transactionFormActionManageFixed;

  /// No description provided for @transactionFormLabelSaveTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como Template'**
  String get transactionFormLabelSaveTemplate;

  /// No description provided for @transactionFormLabelTemplateName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Template'**
  String get transactionFormLabelTemplateName;

  /// No description provided for @transactionFormActionSaving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get transactionFormActionSaving;

  /// No description provided for @transactionFormValidationSameAccount.
  ///
  /// In pt, this message translates to:
  /// **'Selecione contas diferentes.'**
  String get transactionFormValidationSameAccount;

  /// No description provided for @transactionFormCategoryPurchase.
  ///
  /// In pt, this message translates to:
  /// **'Categoria da compra'**
  String get transactionFormCategoryPurchase;

  /// No description provided for @transactionFormInvoiceSource.
  ///
  /// In pt, this message translates to:
  /// **'Cartão (Fatura)'**
  String get transactionFormInvoiceSource;

  /// No description provided for @transactionFormPaymentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento de fatura registrado!'**
  String get transactionFormPaymentSuccess;

  /// No description provided for @transactionFormPaymentError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar pagamento: {error}'**
  String transactionFormPaymentError(String error);

  /// No description provided for @transactionFormChargeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Compra registrada!'**
  String get transactionFormChargeSuccess;

  /// No description provided for @transactionFormChargeError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar compra: {error}'**
  String transactionFormChargeError(String error);

  /// No description provided for @commonToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get commonYesterday;

  /// No description provided for @commonFrom.
  ///
  /// In pt, this message translates to:
  /// **'de'**
  String get commonFrom;

  /// No description provided for @commonTo.
  ///
  /// In pt, this message translates to:
  /// **'para'**
  String get commonTo;

  /// No description provided for @commonNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Sem conta'**
  String get commonNoAccount;

  /// No description provided for @transactionsEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma transação encontrada'**
  String get transactionsEmptyState;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingPreferencesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como você quer ver o app. Dá pra mudar depois.'**
  String get onboardingPreferencesDesc;

  /// No description provided for @onboardingFieldLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get onboardingFieldLanguage;

  /// No description provided for @onboardingFieldCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda principal'**
  String get onboardingFieldCurrency;

  /// No description provided for @onboardingCreateAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua primeira conta'**
  String get onboardingCreateAccountTitle;

  /// No description provided for @onboardingCreateAccountDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: banco, dinheiro, carteira. Você pode adicionar mais depois.'**
  String get onboardingCreateAccountDesc;

  /// No description provided for @onboardingFieldInitialBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial (opcional)'**
  String get onboardingFieldInitialBalance;

  /// No description provided for @onboardingHelperInitialBalance.
  ///
  /// In pt, this message translates to:
  /// **'Se não souber agora, deixe em branco.'**
  String get onboardingHelperInitialBalance;

  /// No description provided for @onboardingErrorNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Crie pelo menos 1 conta para continuar.'**
  String get onboardingErrorNoAccount;

  /// No description provided for @onboardingCategoriesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha suas categorias'**
  String get onboardingCategoriesTitle;

  /// No description provided for @onboardingCategoriesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Deixe marcado o que você usa. Dá pra mudar depois.'**
  String get onboardingCategoriesDesc;

  /// No description provided for @onboardingActionSelectAll.
  ///
  /// In pt, this message translates to:
  /// **'Marcar tudo'**
  String get onboardingActionSelectAll;

  /// No description provided for @onboardingActionDeselectAll.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar tudo'**
  String get onboardingActionDeselectAll;

  /// No description provided for @catHousing.
  ///
  /// In pt, this message translates to:
  /// **'Moradia (aluguel/condomínio)'**
  String get catHousing;

  /// No description provided for @catUtilities.
  ///
  /// In pt, this message translates to:
  /// **'Contas da casa (água, luz, gás)'**
  String get catUtilities;

  /// No description provided for @catInternet.
  ///
  /// In pt, this message translates to:
  /// **'Internet e celular'**
  String get catInternet;

  /// No description provided for @catGroceries.
  ///
  /// In pt, this message translates to:
  /// **'Mercado'**
  String get catGroceries;

  /// No description provided for @catRestaurants.
  ///
  /// In pt, this message translates to:
  /// **'Restaurantes'**
  String get catRestaurants;

  /// No description provided for @catTransport.
  ///
  /// In pt, this message translates to:
  /// **'Transporte (ônibus/uber)'**
  String get catTransport;

  /// No description provided for @catFuel.
  ///
  /// In pt, this message translates to:
  /// **'Combustível'**
  String get catFuel;

  /// No description provided for @catCarMaintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção do carro'**
  String get catCarMaintenance;

  /// No description provided for @catHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get catHealth;

  /// No description provided for @catPharmacy.
  ///
  /// In pt, this message translates to:
  /// **'Farmácia'**
  String get catPharmacy;

  /// No description provided for @catEducation.
  ///
  /// In pt, this message translates to:
  /// **'Educação (escola/cursos)'**
  String get catEducation;

  /// No description provided for @catCreditCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de crédito (gastos)'**
  String get catCreditCard;

  /// No description provided for @catDebts.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas e empréstimos'**
  String get catDebts;

  /// No description provided for @catFees.
  ///
  /// In pt, this message translates to:
  /// **'Taxas e tarifas'**
  String get catFees;

  /// No description provided for @catSubscriptions.
  ///
  /// In pt, this message translates to:
  /// **'Assinaturas (streaming/apps)'**
  String get catSubscriptions;

  /// No description provided for @catPersonal.
  ///
  /// In pt, this message translates to:
  /// **'Cuidados pessoais'**
  String get catPersonal;

  /// No description provided for @catClothing.
  ///
  /// In pt, this message translates to:
  /// **'Roupas'**
  String get catClothing;

  /// No description provided for @catWork.
  ///
  /// In pt, this message translates to:
  /// **'Trabalho (ferramentas/serviços)'**
  String get catWork;

  /// No description provided for @catTaxes.
  ///
  /// In pt, this message translates to:
  /// **'Impostos'**
  String get catTaxes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
