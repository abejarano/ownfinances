import {
  Criteria,
  Filters,
  Operator,
  Order,
} from "@abejarano/ts-mongodb-criteria";
import {
  GeneratedInstance,
  GeneratedInstancePrimitives,
} from "../models/recurring/generated_instance";
import {
  RecurringRule,
  RecurringRulePrimitives,
  RecurringFrequency,
} from "../models/recurring/recurring_rule";
import { Transaction, TransactionStatus } from "../models/transaction";
import type {
  RecurringRuleCreatePayload,
  RecurringRuleUpdatePayload,
  RecurringTemplatePayload,
} from "../http/validation/recurring.validation";
import { GeneratedInstanceMongoRepository } from "../repositories/generated_instance_repository";
import { RecurringRuleMongoRepository } from "../repositories/recurring_rule_repository";
import { TransactionMongoRepository } from "../repositories/transaction_repository";

export interface RecurringPreviewItem {
  recurringRuleId: string;
  date: Date;
  template: RecurringRulePrimitives["template"];
  status: "new" | "already_generated";
}

export class RecurringService {
  constructor(
    private readonly ruleRepo: RecurringRuleMongoRepository,
    private readonly instanceRepo: GeneratedInstanceMongoRepository,
    private readonly transactionRepo: TransactionMongoRepository
  ) {}

  async create(userId: string, payload: RecurringRuleCreatePayload) {
    const template = this.normalizeTemplate(payload.template);
    const startDate = new Date(payload.startDate);
    startDate.setHours(0, 0, 0, 0);
    const signature = this.computeRuleSignature({
      userId,
      frequency: payload.frequency,
      interval: payload.interval,
      startDate,
      template,
    });

    const existing = await this.ruleRepo.one({
      userId,
      signature,
      isActive: true,
    });
    if (existing) {
      const primitives = existing.toPrimitives();
      await this.ruleRepo.deactivateActiveDuplicatesBySignature({
        userId,
        signature,
        keepRecurringRuleId: primitives.recurringRuleId,
      });
      return { rule: existing.toPrimitives() };
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
    });
    try {
      await this.ruleRepo.upsert(rule);
    } catch {
      const concurrent = await this.ruleRepo.one({
        userId,
        signature,
        isActive: true,
      });
      if (concurrent) {
        return { rule: concurrent.toPrimitives() };
      }
      throw new Error("Nao foi possivel criar a recorrencia");
    }
    const created = rule.toPrimitives();
    await this.ruleRepo.deactivateActiveDuplicatesBySignature({
      userId,
      signature,
      keepRecurringRuleId: created.recurringRuleId,
    });
    return { rule: rule.toPrimitives() };
  }

  async delete(userId: string, recurringRuleId: string) {
    const rule = await this.ruleRepo.one({ recurringRuleId });
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 };
    }
    await this.ruleRepo.remove(recurringRuleId);
    return { ok: true };
  }

  async list(userId: string, limit = 50, page = 1) {
    return this.ruleRepo.list(
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
    );
  }

  async getById(userId: string, recurringRuleId: string) {
    const rule = await this.ruleRepo.one({ recurringRuleId });
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 };
    }
    return { rule: rule.toPrimitives() };
  }

  async update(
    userId: string,
    recurringRuleId: string,
    payload: RecurringRuleUpdatePayload
  ) {
    const rule = await this.ruleRepo.one({ recurringRuleId });
    if (!rule || rule.userId !== userId) {
      return { error: "Recurrencia no encontrada", status: 404 };
    }

    const current = rule.toPrimitives();
    const template = payload.template
      ? this.normalizeTemplate(payload.template)
      : current.template;

    const updated = RecurringRule.fromPrimitives({
      ...current,
      ...payload,
      startDate: payload.startDate
        ? new Date(payload.startDate)
        : current.startDate,
      endDate: payload.endDate ? new Date(payload.endDate) : current.endDate,
      template,
    });

    await this.ruleRepo.upsert(updated);
    return { rule: updated.toPrimitives() };
  }

  async preview(
    userId: string,
    period: "monthly",
    date: Date
  ): Promise<RecurringPreviewItem[]> {
    const { start, end } = this.computeRange(period, date);
    const rules = await this.getUserRules(userId);
    const instancesInPeriod = await this.getInstancesInPeriod(
      userId,
      start,
      end
    );

    const result: RecurringPreviewItem[] = [];

    for (const rule of rules) {
      const dates = this.calculateDates(rule, start, end);
      for (const d of dates) {
        const dateStr = d.toISOString().split("T")[0];
        const uniqueKey = `${rule.ruleId}_${dateStr}`;
        const exists = instancesInPeriod.has(uniqueKey);

        result.push({
          recurringRuleId: rule.ruleId,
          date: d,
          template: rule.template,
          status: exists ? "already_generated" : "new",
        });
      }
    }
    return result;
  }

  async run(userId: string, period: "monthly", date: Date) {
    const preview = await this.preview(userId, period, date);
    const toCreate = preview.filter((p) => p.status === "new");

    let count = 0;
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
      });
      const txId = tx.getTransactionId();

      try {
        await this.transactionRepo.upsert(tx);
      } catch {
        // If a recurringUniqueKey race happens, skip without duplicating.
        continue;
      }

      const instance = GeneratedInstance.create(
        item.recurringRuleId,
        userId,
        item.date,
        txId
      );
      try {
        await this.instanceRepo.upsert(instance);
        count++;
      } catch {
        // If a uniqueKey race happens, skip without duplicating.
      }
    }

    return { generated: count };
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
  ) {
    const rule = await this.ruleRepo.one({ recurringRuleId });
    if (!rule || rule.userId !== userId) throw new Error("Rule not found");

    // Check if already materialized
    const dateStr = date.toISOString().split("T")[0];
    const uniqueKey = `${rule.ruleId}_${dateStr}`;

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
      );

    if (existingPage.results.length > 0) {
      throw new Error("Instance already generated");
    }

    // Create Transaction
    const template = overrideTemplate || rule.template;
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
    });
    const txId = tx.getTransactionId();
    await this.transactionRepo.upsert(tx);

    // Create Instance Record
    const instance = GeneratedInstance.create(rule.ruleId, userId, date, txId);
    await this.instanceRepo.upsert(instance);

    return tx;
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
  ) {
    const rule = await this.ruleRepo.one({ recurringRuleId });
    if (!rule || rule.userId !== userId) throw new Error("Rule not found");

    // 1. Update existing rule end date to splitDate - 1 day
    const endDate = new Date(splitDate);
    endDate.setDate(endDate.getDate() - 1);

    // We need to implement update in Repo or just overwrite
    const updatedRule = RecurringRule.fromPrimitives({
      ...rule.toPrimitives(),
      endDate: endDate,
    });
    await this.ruleRepo.upsert(updatedRule);

    // 2. Create new rule starting at splitDate
    return this.create(userId, {
      frequency: rule.frequency,
      interval: rule.interval,
      startDate: splitDate,
      template: this.normalizeTemplate(newTemplate),
    });
  }

  private computeRange(period: "monthly", date: Date) {
    const start = new Date(date);
    start.setDate(1);
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setMonth(end.getMonth() + 1, 0); // Last day of month
    end.setHours(23, 59, 59, 999);
    return { start, end };
  }

  private async getUserRules(userId: string) {
    return this.ruleRepo.searchActive(userId);
  }

  private async getInstancesInPeriod(userId: string, start: Date, end: Date) {
    const instancesPage =
      await this.instanceRepo.list<GeneratedInstancePrimitives>(
        new Criteria(
          Filters.fromValues([
            new Map<string, any>([
              ["field", "userId"],
              ["operator", Operator.EQUAL],
              ["value", userId],
            ]),
            new Map<string, any>([
              ["field", "date"],
              ["operator", Operator.BETWEEN],
              ["value", { start, end }],
            ]),
          ]),
          Order.none()
        )
      );
    return new Set(instancesPage.results.map((i) => i.uniqueKey));
  }

  private calculateDates(
    rule: RecurringRule,
    windowStart: Date,
    windowEnd: Date
  ): Date[] {
    const dates: Date[] = [];
    let current = new Date(rule.startDate);

    // If start date is in future beyond window, no dates
    if (current > windowEnd) return [];
    if (rule.endDate && rule.endDate < windowStart) return [];

    // Advance current to be at least windowStart or close to it
    // For simplicity, we just iterate from startDate. Optimization possible for yearly.

    // Safety break
    let safety = 0;
    while (current <= windowEnd && safety < 1000) {
      if (rule.endDate && current > rule.endDate) break;
      if (current >= windowStart) {
        dates.push(new Date(current));
      }

      // Advance
      if (rule.frequency === RecurringFrequency.Weekly) {
        current.setDate(current.getDate() + 7 * rule.interval);
      } else if (rule.frequency === RecurringFrequency.Monthly) {
        current.setMonth(current.getMonth() + rule.interval);
      } else if (rule.frequency === RecurringFrequency.Yearly) {
        current.setFullYear(current.getFullYear() + rule.interval);
      }
      safety++;
    }

    return dates;
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
    };
  }

  private computeRuleSignature(input: {
    userId: string;
    frequency: RecurringRulePrimitives["frequency"];
    interval: number;
    startDate: Date;
    template: RecurringRulePrimitives["template"];
  }) {
    const dateStr = input.startDate.toISOString().split("T")[0];
    const tags = input.template.tags
      ? [...input.template.tags].filter(Boolean).sort()
      : undefined;

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
    };

    return JSON.stringify(normalized);
  }
}
