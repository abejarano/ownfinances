import {
  Criteria,
  Filters,
  Operator,
  Order,
  type Paginate,
} from "@abejarano/ts-mongodb-criteria"
import {
  GeneratedInstance,
  type GeneratedInstancePrimitives,
} from "../models/recurring/generated_instance"
import {
  RecurringFrequency,
  RecurringRule,
  type RecurringRulePrimitives,
} from "../models/recurring/recurring_rule"
import { Transaction, TransactionStatus } from "../models/transaction"
import { GeneratedInstanceMongoRepository } from "../repositories/generated_instance_repository"
import { RecurringRuleMongoRepository } from "../repositories/recurring_rule_repository"
import { TransactionMongoRepository } from "../repositories/transaction_repository"
import type {
  RecurringRuleCreatePayload,
  RecurringRuleUpdatePayload,
  RecurringTemplatePayload,
} from "../http/validation/recurring.validation"
import type { Result } from "../bootstrap/response"

export interface RecurringPreviewItem {
  recurringRuleId: string
  date: Date
  template: RecurringRulePrimitives["template"]
  status: "new" | "already_generated"
}

export class RecurringService {
  constructor(
    private readonly ruleRepo: RecurringRuleMongoRepository,
    private readonly instanceRepo: GeneratedInstanceMongoRepository,
    private readonly transactionRepo: TransactionMongoRepository
  ) {}

  async create(
    userId: string,
    payload: RecurringRuleCreatePayload
  ): Promise<Result<{ rule: RecurringRulePrimitives }>> {
    const template = this.normalizeTemplate(payload.template)
    const startDate = new Date(payload.startDate)
    startDate.setHours(0, 0, 0, 0)
    const signature = this.computeRuleSignature({
      userId,
      frequency: payload.frequency,
      interval: payload.interval,
      startDate,
      template,
    })

    const existing = await this.ruleRepo.one({
      userId,
      signature,
      isActive: true,
    })
    if (existing) {
      const primitives = existing.toPrimitives()
      await this.ruleRepo.deactivateActiveDuplicatesBySignature({
        userId,
        signature,
        keepRecurringRuleId: primitives.recurringRuleId,
      })
      return { value: { rule: existing.toPrimitives() }, status: 200 }
    }

    const rule = RecurringRule.create({
      signature,
      startDate,
      endDate: payload.endDate ? new Date(payload.endDate) : undefined,
      template,
      userId,
      frequency: payload.frequency,
      interval: payload.interval,
      isActive: payload.isActive ?? true,
      lastRunAt: undefined,
    })

    try {
      await this.ruleRepo.upsert(rule)
    } catch {
      const concurrent = await this.ruleRepo.one({
        userId,
        signature,
        isActive: true,
      })

      if (concurrent) {
        return { value: { rule: concurrent.toPrimitives() }, status: 200 }
      }
      return { error: "Nao foi possivel criar a recorrencia", status: 500 }
    }

    const created = rule.toPrimitives()
    await this.ruleRepo.deactivateActiveDuplicatesBySignature({
      userId,
      signature,
      keepRecurringRuleId: created.recurringRuleId,
    })

    return { value: { rule: rule.toPrimitives() }, status: 201 }
  }

  async delete(
    userId: string,
    recurringRuleId: string
  ): Promise<Result<{ ok: boolean }>> {
    const rule = await this.ruleRepo.one({ recurringRuleId })
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 }
    }
    await this.ruleRepo.remove(recurringRuleId)
    return { value: { ok: true }, status: 200 }
  }

  async list(
    userId: string,
    limit = 50,
    page = 1
  ): Promise<Result<Paginate<RecurringRulePrimitives>>> {
    return {
      value: await this.ruleRepo.list<RecurringRulePrimitives>(
        new Criteria(
          Filters.fromValues([
            new Map<string, any>([
              ["field", "userId"],
              ["operator", Operator.EQUAL],
              ["value", userId],
            ]),
          ]),
          Order.none(),
          limit,
          page
        )
      ),
      status: 200,
    }
  }

  async getById(
    userId: string,
    recurringRuleId: string
  ): Promise<Result<{ rule: RecurringRulePrimitives }>> {
    const rule = await this.ruleRepo.one({ recurringRuleId })
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 }
    }

    return { value: { rule: rule.toPrimitives() }, status: 200 }
  }

  async update(
    userId: string,
    recurringRuleId: string,
    payload: RecurringRuleUpdatePayload
  ): Promise<Result<{ rule: RecurringRulePrimitives }>> {
    const rule = await this.ruleRepo.one({ recurringRuleId })
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 }
    }

    const current = rule.toPrimitives()
    const template = payload.template
      ? this.normalizeTemplate(payload.template)
      : current.template

    const updated = RecurringRule.fromPrimitives({
      ...current,
      ...payload,
      startDate: payload.startDate
        ? new Date(payload.startDate)
        : current.startDate,
      endDate: payload.endDate ? new Date(payload.endDate) : current.endDate,
      template,
    })

    await this.ruleRepo.upsert(updated)
    return { value: { rule: updated.toPrimitives() }, status: 200 }
  }

  async preview(
    userId: string,
    period: "monthly",
    date: Date
  ): Promise<Result<RecurringPreviewItem[]>> {
    const { start, end } = this.computeRange(period, date)
    const rules = await this.getUserRules(userId)
    const instancesInPeriod = await this.getInstancesInPeriod(
      userId,
      start,
      end
    )

    const result: RecurringPreviewItem[] = []

    for (const rule of rules) {
      const rulePrimitives = rule.toPrimitives()
      const dates = this.calculateDates(rule, start, end)
      for (const d of dates) {
        const dateStr = d.toISOString().split("T")[0]
        const uniqueKey = `${rulePrimitives.recurringRuleId}_${dateStr}`
        const exists = instancesInPeriod.has(uniqueKey)

        result.push({
          recurringRuleId: rulePrimitives.recurringRuleId,
          date: d,
          template: rulePrimitives.template,
          status: exists ? "already_generated" : "new",
        })
      }
    }

    return { value: result, status: 200 }
  }

  async run(
    userId: string,
    period: "monthly",
    date: Date
  ): Promise<Result<{ generated: number }>> {
    const preview = await this.preview(userId, period, date)
    if (preview.error) {
      return { error: preview.error, status: preview.status }
    }

    const toCreate = preview.value!.filter((p) => p.status === "new")

    let count = 0
    for (const item of toCreate) {
      const tx = Transaction.create({
        userId,
        date: item.date,
        amount: item.template.amount,
        type: item.template.type,
        currency: item.template.currency,
        categoryId: item.template.categoryId,
        fromAccountId: item.template.fromAccountId,
        toAccountId: item.template.toAccountId,
        note: item.template.note,
        tags: item.template.tags || [],
        status: TransactionStatus.Pending, // Always create as pending
        recurringRuleId: item.recurringRuleId,
      })
      const txId = tx.getTransactionId()

      try {
        await this.transactionRepo.upsert(tx)
      } catch {
        // If a recurringUniqueKey race happens, skip without duplicating.
        continue
      }

      const instance = GeneratedInstance.create(
        item.recurringRuleId,
        userId,
        item.date,
        txId
      )
      try {
        await this.instanceRepo.upsert(instance)
        count++
      } catch {
        // If a uniqueKey race happens, skip without duplicating.
      }
    }

    return { value: { generated: count }, status: 200 }
  }

  /**
   * Materialize a specific occurrence into a real transaction.
   * Used for "Edit Only This" or early payment.
   */
  async materialize(
    userId: string,
    recurringRuleId: string,
    date: Date,
    overrideTemplate?: RecurringRulePrimitives["template"]
  ): Promise<Result<Transaction>> {
    const rule = await this.ruleRepo.one({ recurringRuleId })
    if (!rule || rule.userId !== userId) throw new Error("Rule not found")

    // Check if already materialized
    const dateStr = date.toISOString().split("T")[0]
    const uniqueKey = `${rule.ruleId}_${dateStr}`

    const existingPage =
      await this.instanceRepo.list<GeneratedInstancePrimitives>(
        new Criteria(
          Filters.fromValues([
            new Map([
              ["field", "uniqueKey"],
              ["operator", Operator.EQUAL],
              ["value", uniqueKey],
            ]),
          ]),
          Order.none()
        )
      )

    if (existingPage.results.length > 0) {
      return { error: "Instance already generated", status: 400 }
    }

    // Create Transaction
    const template = overrideTemplate || rule.template
    const tx = Transaction.create({
      userId,
      date: date, // specific date
      amount: template.amount,
      type: template.type,
      currency: template.currency,
      categoryId: template.categoryId,
      fromAccountId: template.fromAccountId,
      toAccountId: template.toAccountId,
      note: template.note,
      tags: template.tags || [],
      status: TransactionStatus.Pending,
      recurringRuleId: rule.ruleId,
    })
    const txId = tx.getTransactionId()
    await this.transactionRepo.upsert(tx)

    // Create Instance Record
    const instance = GeneratedInstance.create(rule.ruleId, userId, date, txId)
    await this.instanceRepo.upsert(instance)

    return { value: tx, status: 200 }
  }

  /**
   * Split a recurring rule into two.
   * Used for "Edit This and Future".
   * Ends current rule yesterday, creates new rule starting today.
   */
  async split(
    userId: string,
    recurringRuleId: string,
    splitDate: Date,
    newTemplate: RecurringTemplatePayload
  ): Promise<Result<{ rule: RecurringRulePrimitives }>> {
    const rule = await this.ruleRepo.one({ recurringRuleId })
    if (!rule || rule.userId !== userId) throw new Error("Rule not found")

    // 1. Update existing rule end date to splitDate - 1 day
    const endDate = new Date(splitDate)
    endDate.setDate(endDate.getDate() - 1)

    // We need to implement update in Repo or just overwrite
    const updatedRule = RecurringRule.fromPrimitives({
      ...rule.toPrimitives(),
      endDate: endDate,
    })
    await this.ruleRepo.upsert(updatedRule)

    // 2. Create new rule starting at splitDate
    return this.create(userId, {
      frequency: rule.frequency,
      interval: rule.interval,
      startDate: splitDate,
      template: this.normalizeTemplate(newTemplate),
    })
  }

  private computeRange(period: "monthly", date: Date) {
    const start = new Date(date)
    start.setDate(1)
    start.setHours(0, 0, 0, 0)
    const end = new Date(start)
    end.setMonth(end.getMonth() + 1, 0) // Last day of month
    end.setHours(23, 59, 59, 999)
    return { start, end }
  }

  private async getUserRules(userId: string) {
    return this.ruleRepo.searchActive(userId)
  }

  private async getInstancesInPeriod(userId: string, start: Date, end: Date) {
    const instancesPage = await this.instanceRepo.search({
      userId: userId,
      date: { $gte: start, $lte: end },
    })
    return new Set(instancesPage.map((i) => i.getUniqueKey()))
  }

  private calculateDates(
    rule: RecurringRule,
    windowStart: Date,
    windowEnd: Date
  ): Date[] {
    const dates: Date[] = []
    let current = new Date(rule.startDate)

    // If start date is in future beyond window, no dates
    if (current > windowEnd) return []
    if (rule.endDate && rule.endDate < windowStart) return []

    // Advance current to be at least windowStart or close to it
    // For simplicity, we just iterate from startDate. Optimization possible for yearly.

    // Safety break
    let safety = 0
    while (current <= windowEnd && safety < 1000) {
      if (rule.endDate && current > rule.endDate) break
      if (current >= windowStart) {
        dates.push(new Date(current))
      }

      // Advance
      if (rule.frequency === RecurringFrequency.Weekly) {
        current.setDate(current.getDate() + 7 * rule.interval)
      } else if (rule.frequency === RecurringFrequency.Monthly) {
        current.setMonth(current.getMonth() + rule.interval)
      } else if (rule.frequency === RecurringFrequency.Yearly) {
        current.setFullYear(current.getFullYear() + rule.interval)
      }
      safety++
    }

    return dates
  }

  private normalizeTemplate(
    template: RecurringTemplatePayload
  ): RecurringRulePrimitives["template"] {
    return {
      ...template,
      currency: template.currency ?? "BRL",
      categoryId: template.categoryId,
      fromAccountId: template.fromAccountId,
      toAccountId: template.toAccountId,
      note: template.note,
      tags: template.tags,
    }
  }

  private computeRuleSignature(input: {
    userId: string
    frequency: RecurringRulePrimitives["frequency"]
    interval: number
    startDate: Date
    template: RecurringRulePrimitives["template"]
  }) {
    const dateStr = input.startDate.toISOString().split("T")[0]
    const tags = input.template.tags
      ? [...input.template.tags].filter(Boolean).sort()
      : undefined

    const normalized = {
      userId: input.userId,
      frequency: input.frequency,
      interval: input.interval,
      startDate: dateStr,
      template: {
        type: input.template.type,
        amount: input.template.amount,
        currency: input.template.currency,
        categoryId: input.template.categoryId ?? null,
        fromAccountId: input.template.fromAccountId ?? null,
        toAccountId: input.template.toAccountId ?? null,
        note: input.template.note ?? null,
        tags: tags ?? null,
      },
    }

    return JSON.stringify(normalized)
  }

  async getPendingSummary(
    userId: string,
    date: Date
  ): Promise<Result<{ month: string; toGenerate: number }>> {
    const preview = await this.preview(userId, "monthly", date)
    if (preview.error) {
      return { error: preview.error, status: preview.status }
    }

    const toGenerate = preview.value!.filter((p) => p.status === "new").length

    const month = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(
      2,
      "0"
    )}`

    return {
      value: {
        month,
        toGenerate,
      },
      status: 200,
    }
  }

  async getSummaryByMonth(
    userId: string,
    months: number = 3
  ): Promise<Result<{ summaries: { month: string; toGenerate: number }[] }>> {
    const summaries = []
    const currentDate = new Date()

    for (let i = 0; i < months; i++) {
      const targetDate = new Date(currentDate)
      targetDate.setMonth(currentDate.getMonth() + i)

      const preview = await this.preview(userId, "monthly", targetDate)
      if (preview.error) {
        return { error: preview.error, status: preview.status }
      }

      const toGenerate = preview.value!.filter((p) => p.status === "new").length

      const month = `${targetDate.getFullYear()}-${String(
        targetDate.getMonth() + 1
      ).padStart(2, "0")}`

      summaries.push({
        month,
        toGenerate,
      })
    }

    return { value: { summaries }, status: 200 }
  }

  async getCatchupSummary(
    userId: string
  ): Promise<Result<{ catchup: { month: string; count: number }[] }>> {
    const currentDate = new Date()
    const rules = await this.getUserRules(userId)

    if (rules.length === 0) {
      return { value: { catchup: [] }, status: 200 }
    }

    // Find earliest start date from active rules
    const earliestStart = rules.reduce((earliest, rule) => {
      return rule.startDate < earliest ? rule.startDate : earliest
    }, rules[0]!.startDate)

    const catchup = []

    // Check up to 12 months back
    const maxMonthsBack = 12
    const startCheckDate = new Date(currentDate)
    startCheckDate.setMonth(startCheckDate.getMonth() - maxMonthsBack)

    const checkStart =
      earliestStart > startCheckDate ? earliestStart : startCheckDate

    // Loop through past months
    let checkDate = new Date(checkStart)
    while (checkDate < currentDate) {
      const preview = await this.preview(userId, "monthly", checkDate)
      const newCount = preview.value!.filter((p) => p.status === "new").length

      if (newCount > 0) {
        const month = `${checkDate.getFullYear()}-${String(
          checkDate.getMonth() + 1
        ).padStart(2, "0")}`
        catchup.push({ month, count: newCount })
      }

      // Move to next month
      checkDate.setMonth(checkDate.getMonth() + 1)
    }

    return { value: { catchup }, status: 200 }
  }
}
