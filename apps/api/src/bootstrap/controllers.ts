import { ControllersModule } from "bun-platform-kit"
import { AccountsController } from "../http/controllers/accounts.controller"
import { AuthController } from "../http/controllers/auth.controller"
import { BanksController } from "../http/controllers/banks.controller"
import { BudgetsController } from "../http/controllers/budgets.controller"
import { CategoriesController } from "../http/controllers/categories.controller"
import { CountriesController } from "../http/controllers/countries.controller"
import { DebtTransactionsController } from "../http/controllers/debt_transactions.controller"
import { DebtsController } from "../http/controllers/debts.controller"
import { GoalsController } from "../http/controllers/goals.controller"
import { ImportJobsController } from "../http/controllers/import_jobs.controller"
import { RecurringController } from "../http/controllers/recurring.controller"
import { ReportsController } from "../http/controllers/reports.controller"
import { SettingsController } from "../http/controllers/settings.controller"
import { TemplatesController } from "../http/controllers/templates.controller"
import { TransactionsController } from "../http/controllers/transactions.controller"
import { TransactionsImportController } from "../http/controllers/transactions_import.controller"

export const controllersModule = () =>
  new ControllersModule([
    AuthController,
    AccountsController,
    BudgetsController,
    CategoriesController,
    CountriesController,
    DebtTransactionsController,
    DebtsController,
    GoalsController,
    ImportJobsController,
    RecurringController,
    ReportsController,
    SettingsController,
    TemplatesController,
    TransactionsImportController,
    TransactionsController,
    BanksController,
  ])
