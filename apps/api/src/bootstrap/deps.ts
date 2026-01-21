import { AccountMongoRepository } from "../repositories/account_repository"
import { BudgetMongoRepository } from "../repositories/budget_repository"
import { CategoryMongoRepository } from "../repositories/category_repository"
import { DebtMongoRepository } from "../repositories/debt_repository"
import { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository"
import { GeneratedInstanceMongoRepository } from "../repositories/generated_instance_repository"
import { GoalContributionMongoRepository } from "../repositories/goal_contribution_repository"
import { GoalMongoRepository } from "../repositories/goal_repository"
import { ImportJobMongoRepository } from "../repositories/import_job_repository"
import { RecurringRuleMongoRepository } from "../repositories/recurring_rule_repository"
import { RefreshTokenMongoRepository } from "../repositories/refresh_token_mongo_repository"
import { TransactionMongoRepository } from "../repositories/transaction_repository"
import { TransactionTemplateMongoRepository } from "../repositories/transaction_template_repository"
import { UserMongoRepository } from "../repositories/user_mongo_repository"
import { UserSettingsRepository } from "../repositories/user_settings_repository"
import { AccountsService } from "../services/accounts_service"
import { AuthService } from "../services/auth_service"
import { BudgetsService } from "../services/budgets_service"
import { CategoriesService } from "../services/categories_service"
import { DebtTransactionsService } from "../services/debt_transactions_service"
import { DebtsService } from "../services/debts_service"
import { GoalContributionsService } from "../services/goal_contributions_service"
import { GoalsService } from "../services/goals_service"
import { RecurringService } from "../services/recurring_service"
import { ReportsService } from "../services/reports_service"
import { TemplateService } from "../services/template_service"
import { TransactionsImportService } from "../services/transactions_import_service"
import { TransactionsService } from "../services/transactions_service"

export type AppDeps = {
  readonly categoryRepo: CategoryMongoRepository
  readonly accountRepo: AccountMongoRepository
  readonly transactionRepo: TransactionMongoRepository
  readonly transactionsService: TransactionsService
  readonly categoriesService: CategoriesService
  readonly accountsService: AccountsService
  readonly userRepo: UserMongoRepository
  readonly refreshTokenRepo: RefreshTokenMongoRepository
  readonly authService: AuthService
  readonly budgetRepo: BudgetMongoRepository
  readonly budgetsService: BudgetsService
  readonly reportsService: ReportsService
  readonly recurringRuleRepo: RecurringRuleMongoRepository
  readonly generatedInstanceRepo: GeneratedInstanceMongoRepository
  readonly recurringService: RecurringService
  readonly templateRepo: TransactionTemplateMongoRepository
  readonly templateService: TemplateService
  readonly debtRepo: DebtMongoRepository
  readonly debtTransactionRepo: DebtTransactionMongoRepository
  readonly debtsService: DebtsService
  readonly debtTransactionsService: DebtTransactionsService
  readonly goalRepo: GoalMongoRepository
  readonly goalContributionRepo: GoalContributionMongoRepository
  readonly goalsService: GoalsService
  readonly goalContributionsService: GoalContributionsService
  readonly importJobRepo: ImportJobMongoRepository
  readonly transactionsImportService: TransactionsImportService
  readonly userSettingsRepo: UserSettingsRepository
}

export class Deps {
  private static instance: AppDeps | null = null

  static getInstance(): AppDeps {
    if (!Deps.instance) {
      Deps.instance = Deps.build()
    }
    return Deps.instance
  }

  private static build(): AppDeps {
    let transactionsService: TransactionsService | null = null
    let categoriesService: CategoriesService | null = null
    let accountsService: AccountsService | null = null
    let authService: AuthService | null = null
    let budgetsService: BudgetsService | null = null
    let reportsService: ReportsService | null = null
    let recurringService: RecurringService | null = null
    let templateService: TemplateService | null = null
    let debtsService: DebtsService | null = null
    let debtTransactionsService: DebtTransactionsService | null = null
    let goalsService: GoalsService | null = null
    let goalContributionsService: GoalContributionsService | null = null
    let transactionsImportService: TransactionsImportService | null = null

    return {
      get categoryRepo() {
        return CategoryMongoRepository.getInstance()
      },
      get accountRepo() {
        return AccountMongoRepository.getInstance()
      },
      get transactionRepo() {
        return TransactionMongoRepository.getInstance()
      },
      get transactionsService() {
        if (!transactionsService) {
          transactionsService = new TransactionsService(
            this.transactionRepo,
            this.accountRepo
          )
        }
        return transactionsService
      },
      get categoriesService() {
        if (!categoriesService) {
          categoriesService = new CategoriesService(
            this.categoryRepo,
            this.transactionRepo
          )
        }
        return categoriesService
      },
      get accountsService() {
        if (!accountsService) {
          accountsService = new AccountsService(
            this.accountRepo,
            this.transactionRepo
          )
        }
        return accountsService
      },
      get userRepo() {
        return UserMongoRepository.getInstance()
      },
      get refreshTokenRepo() {
        return RefreshTokenMongoRepository.getInstance()
      },
      get authService() {
        if (!authService) {
          authService = new AuthService(
            this.userRepo,
            this.refreshTokenRepo,
            this.categoryRepo,
            this.accountRepo
          )
        }
        return authService
      },
      get budgetRepo() {
        return BudgetMongoRepository.getInstance()
      },
      get budgetsService() {
        if (!budgetsService) {
          budgetsService = new BudgetsService(this.budgetRepo)
        }
        return budgetsService
      },
      get reportsService() {
        if (!reportsService) {
          reportsService = new ReportsService(
            this.budgetRepo,
            this.categoryRepo,
            this.transactionRepo
          )
        }
        return reportsService
      },
      get recurringRuleRepo() {
        return RecurringRuleMongoRepository.getInstance()
      },
      get generatedInstanceRepo() {
        return GeneratedInstanceMongoRepository.getInstance()
      },
      get recurringService() {
        if (!recurringService) {
          recurringService = new RecurringService(
            this.recurringRuleRepo,
            this.generatedInstanceRepo,
            this.transactionRepo
          )
        }
        return recurringService
      },
      get templateRepo() {
        return TransactionTemplateMongoRepository.getInstance()
      },
      get templateService() {
        if (!templateService) {
          templateService = new TemplateService(this.templateRepo)
        }
        return templateService
      },
      get debtRepo() {
        return DebtMongoRepository.getInstance()
      },
      get debtTransactionRepo() {
        return DebtTransactionMongoRepository.getInstance()
      },
      get debtsService() {
        if (!debtsService) {
          debtsService = new DebtsService(
            this.debtRepo,
            this.debtTransactionRepo
          )
        }
        return debtsService
      },
      get debtTransactionsService() {
        if (!debtTransactionsService) {
          debtTransactionsService = new DebtTransactionsService(
            this.debtTransactionRepo,
            this.debtRepo,
            this.accountRepo,
            this.transactionRepo,
            this.categoryRepo
          )
        }
        return debtTransactionsService
      },
      get goalRepo() {
        return GoalMongoRepository.getInstance()
      },
      get goalContributionRepo() {
        return GoalContributionMongoRepository.getInstance()
      },
      get goalsService() {
        if (!goalsService) {
          goalsService = new GoalsService(
            this.goalRepo,
            this.goalContributionRepo,
            this.transactionRepo
          )
        }
        return goalsService
      },
      get goalContributionsService() {
        if (!goalContributionsService) {
          goalContributionsService = new GoalContributionsService(
            this.goalContributionRepo,
            this.goalRepo,
            this.accountRepo,
            this.transactionRepo
          )
        }
        return goalContributionsService
      },
      get importJobRepo() {
        return ImportJobMongoRepository.getInstance()
      },
      get transactionsImportService() {
        if (!transactionsImportService) {
          transactionsImportService = new TransactionsImportService(
            this.transactionRepo,
            this.importJobRepo,
            this.accountRepo
          )
        }
        return transactionsImportService
      },
      get userSettingsRepo() {
        return UserSettingsRepository.getInstance()
      },
    }
  }

  static resolve<T>(key: keyof AppDeps): T {
    const deps = Deps.getInstance()
    return deps[key] as unknown as T
  }
}

export function buildDeps(): AppDeps {
  return Deps.getInstance()
}
