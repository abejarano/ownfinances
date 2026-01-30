import {
  Criteria,
  Filters,
  Operator,
  Order,
  type Paginate,
} from "@abejarano/ts-mongodb-criteria"
import type { Result } from "../bootstrap/response"
import type {
  RecurringRuleCreatePayload,
  RecurringRuleUpdatePayload,
  RecurringTemplatePayload,
} from "../http/validation/recurring.validation"
import {
  GeneratedInstance,
  type GeneratedInstancePrimitives,
} from "@desquadra/database"
import {
  RecurringFrequency,
  RecurringRule,
  type RecurringRulePrimitives,
} from "@desquadra/database"
import { Transaction, TransactionStatus } from "@desquadra/database"
import { GeneratedInstanceMongoRepository } from "@desquadra/database"
import { RecurringRuleMongoRepository } from "@desquadra/database"
import { TransactionMongoRepository } from "@desquadra/database"
import { computePeriodRange } from "../shared/dates"

export interface RecurringPreviewItem {
  recurringRuleId: string
  date: Date
  template: RecurringRulePrimitives["template"]
  status: "new" | "already_generated" | "ignored"
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

  async ignore(
    userId: string,
    recurringRuleId: string,
    date: Date
  ): Promise<Result<{ instance: GeneratedInstancePrimitives }>> {
    const rule = await this.ruleRepo.one({ recurringRuleId })
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 }
    }

    // Check if already exists (generated or ignored)
    const dateStr = date.toISOString().split("T")[0]
    const uniqueKey = `${recurringRuleId}_${dateStr}`
    const existing = await this.instanceRepo.one({ uniqueKey })

    if (existing) {
      // If already generated/ignored, we might want to ensure it is ignored now?
      // For MVP, if it's already "generated" (has tx), we can't just ignore it without deleting tx.
      // If it's "ignored", do nothing.
      // Let's assume frontend calls this only on "new" items.
      return { error: "Instance already processed", status: 400 }
    }

    const instance = GeneratedInstance.create(
      recurringRuleId,
      userId,
      date,
      undefined,
      "ignored"
    )

    await this.instanceRepo.upsert(instance)
    return { value: { instance: instance.toPrimitives() }, status: 201 }
  }

  async undoIgnore(
    userId: string,
    recurringRuleId: string,
    date: Date
  ): Promise<Result<{ ok: boolean }>> {
    const dateStr = date.toISOString().split("T")[0]
    const uniqueKey = `${recurringRuleId}_${dateStr}`

    const instance = await this.instanceRepo.one({ uniqueKey, userId })
    if (!instance) {
      return { error: "Instance not found", status: 404 }
    }

    const prim = instance.toPrimitives()
    if (prim.status !== "ignored") {
      return { error: "Instance is not ignored", status: 400 }
    }

    await this.instanceRepo.remove(prim.generatedInstanceId)
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
    const startTotal = performance.now()
    console.log(
      `[RecurringService] Preview started for user ${userId}, period ${period}, date ${date.toISOString()}`
    )
    const { start, end } = this.computeRange(period, date)

    const startRules = performance.now()
    const rules = await this.getUserRules(userId)
    console.log(
      `[RecurringService] Found ${rules.length} active rules (took ${(performance.now() - startRules).toFixed(2)}ms)`
    )

    const startInstances = performance.now()
    const instancesInPeriod = await this.getInstancesInPeriod(
      userId,
      start,
      end
    )
    console.log(
      `[RecurringService] Loaded instances (took ${(performance.now() - startInstances).toFixed(2)}ms)`
    )

    const result: RecurringPreviewItem[] = []

    for (const rule of rules) {
      const startRule = performance.now()
      try {
        const rulePrimitives = rule.toPrimitives()
        const dates = this.calculateDates(rule, start, end)
        for (const d of dates) {
          const dateStr = d.toISOString().split("T")[0]
          const uniqueKey = `${rulePrimitives.recurringRuleId}_${dateStr}`
          const instanceState = instancesInPeriod.get(uniqueKey)

          let status: RecurringPreviewItem["status"] = "new"
          if (instanceState === "created") status = "already_generated"
          if (instanceState === "ignored") status = "ignored"

          result.push({
            recurringRuleId: rulePrimitives.recurringRuleId,
            date: d,
            template: rulePrimitives.template,
            status,
          })
        }
        const ruleTime = performance.now() - startRule
        if (ruleTime > 100) {
          console.warn(
            `[RecurringService] Slow rule ${rule.ruleId}: ${ruleTime.toFixed(2)}ms`
          )
        }
      } catch (e) {
        console.error(
          `[RecurringService] Error processing rule ${rule.ruleId}:`,
          e
        )
      }
    }

    console.log(
      `[RecurringService] Preview finished, returning ${result.length} items (Total: ${(performance.now() - startTotal).toFixed(2)}ms)`
    )
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
    return computePeriodRange(period, date)
  }

  private async getUserRules(userId: string) {
    return this.ruleRepo.searchActive(userId)
  }

  private async getInstancesInPeriod(userId: string, start: Date, end: Date) {
    const instancesPage = await this.instanceRepo.search({
      userId: userId,
      date: { $gte: start, $lte: end },
    })
    const map = new Map<string, "created" | "ignored">()
    instancesPage.forEach((i) => {
      const p = i.toPrimitives()
      // Fallback for legacy data that doesn't have status yet -> 'created'
      const status = (p as any).status || "created"
      map.set(p.uniqueKey, status)
    })
    return map
  }

  private calculateDates(
    rule: RecurringRule,
    windowStart: Date,
    windowEnd: Date
  ): Date[] {
    const dates: Date[] = []

    // Safety: Ensure interval is at least 1
    if (rule.interval < 1) {
      console.warn(
        `[RecurringService] Rule ${rule.ruleId} has invalid interval ${rule.interval}, treating as 1`
      )
      // Hack: treat as 1 explicitly for calculation without mutating rule object deeper
      // Actually we can't mutate rule here easily, so let's just use a local var
    }
    const safeInterval = Math.max(1, rule.interval)

    // If start date is in future beyond window, no dates
    if (new Date(rule.startDate) > windowEnd) return []
    if (rule.endDate && rule.endDate < windowStart) return []

    const startDay = new Date(rule.startDate).getDate()
    let current = new Date(rule.startDate)

    // Optimization: Jump to near windowStart to avoid iterating from ancient history
    // We want 'current' to be the first occurrence >= windowStart (or just before it)
    if (current < windowStart) {
      if (rule.frequency === RecurringFrequency.Monthly) {
        // Calculate months difference
        const monthsDiff =
          (windowStart.getFullYear() - current.getFullYear()) * 12 +
          (windowStart.getMonth() - current.getMonth())
        if (monthsDiff > 0) {
          // How many intervals fit?
          const intervalsToSkip = Math.floor(monthsDiff / safeInterval)
          // Add them
          if (intervalsToSkip > 0) {
            current.setDate(1)
            current.setMonth(
              current.getMonth() + intervalsToSkip * safeInterval
            )

            const daysInMonth = new Date(
              current.getFullYear(),
              current.getMonth() + 1,
              0
            ).getDate()
            const targetDay = Math.min(startDay, daysInMonth)
            current.setDate(targetDay)
          }
        }
      } else if (rule.frequency === RecurringFrequency.Weekly) {
        const oneWeekMs = 7 * 24 * 60 * 60 * 1000
        const intervalMs = oneWeekMs * safeInterval
        const diffMs = windowStart.getTime() - current.getTime()
        if (diffMs > 0) {
          const skips = Math.floor(diffMs / intervalMs)
          if (skips > 0) {
            current = new Date(current.getTime() + skips * intervalMs)
          }
        }
      } else if (rule.frequency === RecurringFrequency.Yearly) {
        const diffYears = windowStart.getFullYear() - current.getFullYear()
        if (diffYears > 0) {
          const skips = Math.floor(diffYears / safeInterval)
          if (skips > 0) {
            current.setFullYear(current.getFullYear() + skips * safeInterval)
          }
        }
      }
    }

    // Safety break
    let safety = 0
    while (current <= windowEnd && safety < 2000) {
      if (rule.endDate && current > rule.endDate) break

      if (current >= windowStart) {
        dates.push(new Date(current))
      }

      const prevTime = current.getTime()

      // Advance
      if (rule.frequency === RecurringFrequency.Weekly) {
        current.setDate(current.getDate() + 7 * safeInterval)
      } else if (rule.frequency === RecurringFrequency.Monthly) {
        current.setDate(1)
        current.setMonth(current.getMonth() + safeInterval)

        const daysInMonth = new Date(
          current.getFullYear(),
          current.getMonth() + 1,
          0
        ).getDate()
        const targetDay = Math.min(startDay, daysInMonth)
        current.setDate(targetDay)
      } else if (rule.frequency === RecurringFrequency.Yearly) {
        current.setFullYear(current.getFullYear() + safeInterval)
      } else {
        break
      }

      // Infinite loop guard
      if (current.getTime() === prevTime) {
        console.error(
          `[RecurringService] Infinite loop detected for rule ${rule.ruleId}`
        )
        break
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
