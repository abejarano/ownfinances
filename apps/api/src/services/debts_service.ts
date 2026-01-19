import type { Paginate } from "@abejarano/ts-mongodb-criteria"
import type { Result } from "../bootstrap/response"
import { buildDebtTransactionsCriteria } from "../http/criteria/debt_transactions.criteria"
import type {
  DebtCreatePayload,
  DebtUpdatePayload,
} from "../http/validation/debts.validation"

import type { DebtPrimitives } from "../models/debt"
import { Debt } from "../models/debt"
import type { DebtTransactionPrimitives } from "../models/debt_transaction"
import { DebtTransactionType } from "../models/debt_transaction"
import type { DebtMongoRepository } from "../repositories/debt_repository"
import type { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository"

export class DebtsService {
  constructor(
    private readonly debts: DebtMongoRepository,
    private readonly debtTransactions: DebtTransactionMongoRepository
  ) {}

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
      isActive: payload.isActive ?? true,
    })

    await this.debts.upsert(debt)
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
}

function startOfDay(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}
