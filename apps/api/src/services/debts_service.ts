import {
  Criteria,
  Filters,
  Operator,
  Order,
  type FilterInputValue,
  type Paginate,
} from "@abejarano/ts-mongodb-criteria"
import type { Result } from "../bootstrap/response"
import { buildDebtTransactionsCriteria } from "../http/criteria/debt_transactions.criteria"
import type {
  DebtCreatePayload,
  DebtUpdatePayload,
} from "../http/validation/debts.validation"

import type { DebtPrimitives } from "../models/debt"
import { Debt } from "../models/debt"
import type { DebtTransactionPrimitives } from "../models/debt_transaction"
import {
  DebtTransaction,
  DebtTransactionType,
} from "../models/debt_transaction"
import type { DebtMongoRepository } from "../repositories/debt_repository"
import type { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository"

export class DebtsService {
  constructor(
    private readonly debts: DebtMongoRepository,
    private readonly debtTransactions: DebtTransactionMongoRepository
  ) {}

  async list(
    userId: string,
    criteria: Criteria
  ): Promise<Result<Paginate<DebtPrimitives>>> {
    const debtsResult = await this.debts.list<DebtPrimitives>(criteria)
    const transactionSums = await this.debtTransactions.sumByDebt(userId)

    // Map: DebtId -> Balance
    const balanceMap = new Map<string, number>()
    
    for (const row of transactionSums) {
      const current = balanceMap.get(row.debtId) ?? 0
      let modifier = 0
      if (
        row.type === DebtTransactionType.Charge ||
        row.type === DebtTransactionType.Fee ||
        row.type === DebtTransactionType.Interest
      ) {
        modifier = row.total
      } else if (row.type === DebtTransactionType.Payment) {
        modifier = -row.total
      }
      balanceMap.set(row.debtId, current + modifier)
    }

    const enriched = debtsResult.results.map((item) => {
      const debt = Debt.fromPrimitives(item)
      const primitives = debt.toPrimitives()
      const computedBalance = balanceMap.get(primitives.debtId) ?? 0
      
      primitives.amountDue = Math.max(0, computedBalance)
      primitives.creditBalance = computedBalance < 0 ? Math.abs(computedBalance) : 0
      
      return primitives
    })

    return {
      value: {
        ...debtsResult,
        results: enriched,
      },
      status: 200,
    }
  }

  async create(
    userId: string,
    payload: DebtCreatePayload
  ): Promise<Result<{ debt: DebtPrimitives }>> {
    const debt = Debt.create({
      userId,
      name: payload.name!,
      type: payload.type!,
      linkedAccountId: payload.linkedAccountId,
      currency: payload.currency ?? "BRL",
      dueDay: payload.dueDay,
      minimumPayment: payload.minimumPayment,
      interestRateAnnual: payload.interestRateAnnual,
      initialBalance: payload.initialBalance,
      isActive: payload.isActive ?? true,
    })

    await this.debts.upsert(debt)

    if (payload.initialBalance && payload.initialBalance > 0) {
      const initialTx = DebtTransaction.create({
        userId,
        debtId: debt.getDebtId(),
        type: DebtTransactionType.Charge,
        amount: payload.initialBalance,
        note: "Saldo inicial",
        date: new Date(),
      })
      await this.debtTransactions.upsert(initialTx)
    }
    return { value: { debt: debt.toPrimitives() }, status: 201 }
  }

  async update(
    userId: string,
    debtId: string,
    payload: DebtUpdatePayload
  ): Promise<Result<{ debt: DebtPrimitives }>> {
    const existing = await this.debts.one({ userId, debtId })
    if (!existing) {
      return { error: "Deuda no encontrada", status: 404 }
    }

    // Rule: initialBalance is not editable
    if (payload.initialBalance) {
      delete payload.initialBalance
    }

    const existingPrimitives = existing.toPrimitives()
    const merged: DebtPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.debtId,
      debtId: existingPrimitives.debtId,
      userId: existingPrimitives.userId,
      linkedAccountId:
        payload.linkedAccountId ?? existingPrimitives.linkedAccountId,
      currentBalance: existingPrimitives.currentBalance ?? 0,
      updatedAt: new Date(),
    }

    const debt = Debt.fromPrimitives(merged)
    await this.debts.upsert(debt)
    return { value: { debt: debt.toPrimitives() }, status: 200 }
  }

  async remove(
    userId: string,
    debtId: string
  ): Promise<Result<{ ok: boolean }>> {
    const deleted = await this.debts.delete(userId, debtId)
    if (!deleted) {
      return { error: "Deuda no encontrada", status: 404 }
    }
    return { value: { ok: true }, status: 200 }
  }

  async summary(
    userId: string,
    debtId: string
  ): Promise<
    Result<{
      balanceComputed: number
      amountDue: number
      creditBalance: number
      paymentsThisMonth: number
      nextDueDate: Date | null
    }>
  > {
    const debt = await this.debts.one({ userId, debtId })
    if (!debt) {
      return { error: "Deuda no encontrada", status: 404 }
    }

    const totals = await this.debtTransactions.sumByDebt(userId, { debtId })
    const byType = new Map<DebtTransactionType, number>()
    for (const row of totals) {
      byType.set(row.type, (byType.get(row.type) ?? 0) + row.total)
    }

    const charges = byType.get(DebtTransactionType.Charge) ?? 0
    const fees = byType.get(DebtTransactionType.Fee) ?? 0
    const interest = byType.get(DebtTransactionType.Interest) ?? 0
    const payments = byType.get(DebtTransactionType.Payment) ?? 0
    const balanceComputed = charges + fees + interest - payments

    const now = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
    const monthEnd = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
      23,
      59,
      59,
      999
    )
    const paymentRows = await this.debtTransactions.sumByDebt(userId, {
      debtId,
      start: monthStart,
      end: monthEnd,
      types: [DebtTransactionType.Payment],
    })
    const paymentsThisMonth = paymentRows.reduce(
      (acc, row) => acc + row.total,
      0
    )

    const nextDueDate = this.nextDueDate(debt.toPrimitives().dueDay, now)
    const amountDue = Math.max(0, balanceComputed)
    const creditBalance = balanceComputed < 0 ? Math.abs(balanceComputed) : 0

    return {
      value: {
        balanceComputed,
        amountDue,
        creditBalance,
        paymentsThisMonth,
        nextDueDate,
      },
      status: 200,
    }
  }

  private nextDueDate(dueDay?: number, now?: Date) {
    if (!dueDay) return null
    const today = now ?? new Date()
    const year = today.getFullYear()
    const month = today.getMonth()

    const candidate = this.buildDueDate(year, month, dueDay)
    if (candidate >= startOfDay(today)) {
      return candidate
    }
    return this.buildDueDate(year, month + 1, dueDay)
  }

  private buildDueDate(year: number, month: number, dueDay: number) {
    const maxDay = new Date(year, month + 1, 0).getDate()
    const day = Math.min(dueDay, maxDay)
    return new Date(year, month, day)
  }

  async history(
    userId: string,
    debtId: string,
    month?: string
  ): Promise<Result<Paginate<DebtTransactionPrimitives>>> {
    const debt = await this.debts.one({ userId, debtId })
    if (!debt) {
      return { error: "Deuda no encontrada", status: 404 }
    }

    let dateFrom: string | undefined
    let dateTo: string | undefined

    if (month) {
      // month format: YYYY-MM
      const [yearStr, monthStr] = month.split("-")
      const year = parseInt(yearStr!, 10)
      const monthNum = parseInt(monthStr!, 10) - 1 // JavaScript months are 0-indexed
      const start = new Date(year, monthNum, 1)
      const end = new Date(year, monthNum + 1, 0, 23, 59, 59, 999)
      dateFrom = start.toISOString()
      dateTo = end.toISOString()
    } else {
      // Si no se especifica mes, usar el mes actual
      const now = new Date()
      const start = new Date(now.getFullYear(), now.getMonth(), 1)
      const end = new Date(
        now.getFullYear(),
        now.getMonth() + 1,
        0,
        23,
        59,
        59,
        999
      )
      dateFrom = start.toISOString()
      dateTo = end.toISOString()
    }

    const query: Record<string, string | undefined> = {
      debtId,
      dateFrom,
      dateTo,
    }
    const criteria = buildDebtTransactionsCriteria(query, userId)
    const result =
      await this.debtTransactions.list<DebtTransactionPrimitives>(criteria)

    return {
      value: {
        ...result,
        results: result.results.map((item) => item),
      },
      status: 200,
    }
  }

  async overview(
    userId: string
  ): Promise<
    Result<{
      totalAmountDue: number
      totalPaidThisMonth: number
      nextDue: {
        debtId: string
        name: string
        date: Date
        amountDue: number
        isOverdue: boolean
      } | null
      flags: { hasOverdue: boolean }
      counts: { activeDebts: number }
    }>
  > {
    // Build criteria for active debts
    // Build criteria for active debts
    const filters = [
      new Map<string, FilterInputValue>([
        ["field", "userId"],
        ["operator", Operator.EQUAL],
        ["value", userId],
      ]),
      new Map<string, FilterInputValue>([
        ["field", "isActive"],
        ["operator", Operator.EQUAL],
        ["value", true],
      ]),
    ]
    // @ts-ignore
    const criteria = new Criteria(Filters.fromValues(filters), Order.none())

    const allDebts = await this.debts.list<DebtPrimitives>(criteria)
    const activeDebts = allDebts.results.map((d) =>
      Debt.fromPrimitives(d).toPrimitives()
    )

    if (activeDebts.length === 0) {
      return {
        value: {
          totalAmountDue: 0,
          totalPaidThisMonth: 0,
          nextDue: null,
          flags: { hasOverdue: false },
          counts: { activeDebts: 0 },
        },
        status: 200,
      }
    }

    const now = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
    const monthEnd = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
      23,
      59,
      59,
      999
    )

    const debtsData = await Promise.all(
      activeDebts.map(async (debt) => {
        const totals = await this.debtTransactions.sumByDebt(userId, {
          debtId: debt.debtId,
        })
        let balance = 0
        totals.forEach((t) => {
          if (t.type === DebtTransactionType.Payment) balance -= t.total
          else balance += t.total
        })
        const amountDue = Math.max(0, balance)

        const paymentsRows = await this.debtTransactions.sumByDebt(userId, {
          debtId: debt.debtId,
          start: monthStart,
          end: monthEnd,
          types: [DebtTransactionType.Payment],
        })
        const paidMonth = paymentsRows.reduce((acc, r) => acc + r.total, 0)

        const nextDate = this.nextDueDate(debt.dueDay, now)

        return {
          debt,
          amountDue,
          paidMonth,
          nextDate,
          balance,
        }
      })
    )

    const totalAmountDue = debtsData.reduce((acc, d) => acc + d.amountDue, 0)
    const totalPaidThisMonth = debtsData.reduce(
      (acc, d) => acc + d.paidMonth,
      0
    )

    const todayStart = startOfDay(now)
    const overdueDebts = debtsData.filter(
      (d) => d.nextDate && d.nextDate < todayStart && d.amountDue > 0
    )
    const futureDebts = debtsData.filter(
      (d) => d.nextDate && d.nextDate >= todayStart && d.amountDue > 0
    )

    let nextDueItem = null
    const hasOverdue = overdueDebts.length > 0

    if (hasOverdue) {
      overdueDebts.sort((a, b) => a.nextDate!.getTime() - b.nextDate!.getTime())
      const selected = overdueDebts[0]
      if (selected) {
        nextDueItem = {
          debtId: selected.debt.id ?? "",
          name: selected.debt.name,
          date: selected.nextDate!,
          amountDue: selected.amountDue,
          isOverdue: true,
        }
      }
    } else if (futureDebts.length > 0) {
      futureDebts.sort((a, b) => a.nextDate!.getTime() - b.nextDate!.getTime())
      const selected = futureDebts[0]
      if (selected) {
        nextDueItem = {
          debtId: selected.debt.id ?? "",
          name: selected.debt.name,
          date: selected.nextDate!,
          amountDue: selected.amountDue,
          isOverdue: false,
        }
      }
    }

    return {
      value: {
        totalAmountDue,
        totalPaidThisMonth,
        nextDue: nextDueItem,
        flags: { hasOverdue },
        counts: { activeDebts: activeDebts.length },
      },
      status: 200,
    }
  }
}

function startOfDay(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}
