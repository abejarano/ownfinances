import type { Result } from "../bootstrap/response"
import type { BudgetPeriodType } from "../models/budget"
import type { BudgetMongoRepository } from "../repositories/budget_repository"
import type { CategoryMongoRepository } from "../repositories/category_repository"
import type { TransactionMongoRepository } from "../repositories/transaction_repository"
import type { DateInput } from "../shared/dates"
import { computePeriodRange } from "../shared/dates"

export type Summary = {
  range: { start: Date; end: Date }
  totals: {
    plannedIncome: number
    plannedExpense: number
    plannedNet: number
    actualIncome: number
    actualExpense: number
    actualNet: number
    remainingIncome: number
    remainingExpense: number
    remainingNet: number
  }
  byCategory: Array<{
    categoryId: string
    kind: "income" | "expense"
    planned: number
    actual: number
    actualByCurrency: Record<string, number>
    remaining: number
    progressPct: number
  }>
  flags: {
    overspentCategories: string[]
    isDeficitVsPlan: boolean
  }
}

export class ReportsService {
  constructor(
    private readonly budgets: BudgetMongoRepository,
    private readonly categories: CategoryMongoRepository,
    private readonly transactions: TransactionMongoRepository
  ) {}

  async summary(
    userId: string,
    period: BudgetPeriodType,
    date: DateInput
  ): Promise<Result<Summary>> {
    const range = computePeriodRange(period, date)

    const budget = await this.budgets.one({
      userId,
      periodType: period,
      startDate: range.start,
      endDate: range.end,
    })
    const budgetPrimitives = budget?.toPrimitives()

    const categories = await this.categories.search(userId)
    const sums = await this.transactions.sumByCategory(
      userId,
      range.start,
      range.end
    )

    const plannedByCategory = new Map<string, number>()
    if (budgetPrimitives?.lines) {
      for (const line of budgetPrimitives.lines) {
        plannedByCategory.set(
          line.categoryId,
          (plannedByCategory.get(line.categoryId) ?? 0) + line.plannedAmount
        )
      }
    }

    const actualByCategory = new Map<string, number>()
    const actualByCategoryCurrency = new Map<string, Map<string, number>>()
    for (const row of sums) {
      actualByCategory.set(
        row.categoryId,
        (actualByCategory.get(row.categoryId) ?? 0) + row.total
      )
      const categoryCurrencies =
        actualByCategoryCurrency.get(row.categoryId) ?? new Map()
      categoryCurrencies.set(
        row.currency,
        (categoryCurrencies.get(row.currency) ?? 0) + row.total
      )
      actualByCategoryCurrency.set(row.categoryId, categoryCurrencies)
    }

    const byCategory = categories.map((category) => {
      const planned = plannedByCategory.get(category.categoryId) ?? 0
      const actual = actualByCategory.get(category.categoryId) ?? 0
      const remaining = planned - actual
      const progressPct = planned > 0 ? (actual / planned) * 100 : 0
      const currencyTotals = actualByCategoryCurrency.get(category.categoryId)
      const actualByCurrency = currencyTotals
        ? Object.fromEntries(currencyTotals.entries())
        : {}
      return {
        categoryId: category.categoryId,
        kind: category.kind,
        planned,
        actual,
        actualByCurrency,
        remaining,
        progressPct,
      }
    })

    const totals = byCategory.reduce(
      (acc, item) => {
        if (item.kind === "income") {
          acc.plannedIncome += item.planned
          acc.actualIncome += item.actual
        } else {
          acc.plannedExpense += item.planned
          acc.actualExpense += item.actual
        }
        return acc
      },
      {
        plannedIncome: 0,
        plannedExpense: 0,
        actualIncome: 0,
        actualExpense: 0,
      }
    )

    const plannedNet = totals.plannedIncome - totals.plannedExpense
    const actualNet = totals.actualIncome - totals.actualExpense

    const remainingIncome = totals.plannedIncome - totals.actualIncome
    const remainingExpense = totals.plannedExpense - totals.actualExpense
    const remainingNet = plannedNet - actualNet

    const overspentCategories = byCategory
      .filter((item) => item.kind === "expense" && item.remaining < 0)
      .map((item) => item.categoryId)

    return {
      value: {
        range,
        totals: {
          plannedIncome: totals.plannedIncome,
          plannedExpense: totals.plannedExpense,
          plannedNet,
          actualIncome: totals.actualIncome,
          actualExpense: totals.actualExpense,
          actualNet,
          remainingIncome,
          remainingExpense,
          remainingNet,
        },
        byCategory,
        flags: {
          overspentCategories,
          isDeficitVsPlan: actualNet < plannedNet,
        },
      },
      status: 200,
    }
  }

  async balances(
    userId: string,
    period: BudgetPeriodType,
    date: DateInput
  ): Promise<
    Result<{
      range: { start: Date; end: Date }
      balances: Array<{ accountId: string; balance: number }>
    }>
  > {
    const range = computePeriodRange(period, date)
    const balances = await this.transactions.sumByAccount(
      userId,
      range.start,
      range.end
    )
    return {
      value: {
        range,
        balances,
      },
      status: 200,
    }
  }
}
