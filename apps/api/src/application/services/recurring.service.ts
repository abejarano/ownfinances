import { Criteria, Filters, Operator, Order } from "@abejarano/ts-mongodb-criteria";
import { ObjectId } from "mongodb";
import * as crypto from "crypto";
import { GeneratedInstance, GeneratedInstanceRepository } from "../../domain/recurring/generated_instance";
import { RecurringRule, RecurringRulePrimitives, RecurringRuleRepository } from "../../domain/recurring/recurring_rule";
import type { TransactionRepository } from "../../domain/transaction";
import { Transaction } from "../../domain/transaction";

export interface RecurringPreviewItem {
  ruleId: string;
  date: Date;
  template: RecurringRulePrimitives["template"];
  status: "new" | "already_generated";
}

export class RecurringService {
  constructor(
    private readonly ruleRepo: RecurringRuleRepository,
    private readonly instanceRepo: GeneratedInstanceRepository,
    private readonly transactionRepo: TransactionRepository,
  ) {}

  async create(userId: string, payload: Omit<RecurringRulePrimitives, "id" | "ruleId" | "userId" | "active">) {
    const id = new ObjectId().toHexString();
    const ruleId = crypto.randomUUID();
    const rule = RecurringRule.fromPrimitives({
      ...payload,
      id,
      ruleId,
      userId,
      active: true,
      lastRunAt: undefined,
    });
    await this.ruleRepo.upsert(rule);
    return rule;
  }

  async delete(userId: string, id: string) {
    const rule = await this.ruleRepo.byId(id);
    if (!rule || rule.userId !== userId) return; // Silent fail or throw
    await this.ruleRepo.remove(id);
  }

  async list(userId: string, limit = 50, page = 1) {
    return this.ruleRepo.list(
      new Criteria(
        Filters.fromValues([
          new Map<string, any>([["field", "userId"], ["operator", Operator.EQUAL], ["value", userId]]),
        ]),
        Order.none(),
        limit,
        page,
      ),
    );
  }

  async preview(userId: string, period: "monthly", date: Date): Promise<RecurringPreviewItem[]> {
    const { start, end } = this.computeRange(period, date);
    const rules = await this.getUserRules(userId);
    const instancesInPeriod = await this.getInstancesInPeriod(userId, start, end);

    const result: RecurringPreviewItem[] = [];

    for (const rule of rules) {
      const dates = this.calculateDates(rule, start, end);
      for (const d of dates) {
        const dateStr = d.toISOString().split("T")[0];
        const uniqueKey = `${rule.id}_${dateStr}`;
        const exists = instancesInPeriod.has(uniqueKey);

        result.push({
          ruleId: rule.ruleId,
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
      const txId = new ObjectId().toHexString();
      const tx = Transaction.fromPrimitives({
        id: txId,
        transactionId: txId,
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
        status: "pending", // Always create as pending
        createdAt: new Date(),
        updatedAt: new Date(),
        recurringRuleId: item.ruleId,
      });

      await this.transactionRepo.upsert(tx);

      const instanceId = crypto.randomUUID();
      const instanceIdMongo = new ObjectId().toHexString();
      const instance = GeneratedInstance.create(
        instanceIdMongo,
        instanceId,
        item.ruleId,
        userId,
        item.date,
        txId,
      );
      await this.instanceRepo.upsert(instance);
      count++;
    }

    return { generated: count };
  }

  /**
   * Materialize a specific occurrence into a real transaction.
   * Used for "Edit Only This" or early payment.
   */
  async materialize(userId: string, ruleId: string, date: Date, overrideTemplate?: RecurringRulePrimitives["template"]) {
      const rule = await this.ruleRepo.byId(ruleId);
      if (!rule || rule.userId !== userId) throw new Error("Rule not found");

      // Check if already materialized
      const dateStr = date.toISOString().split("T")[0];
      const uniqueKey = `${rule.id}_${dateStr}`;
      
      const existing = await this.instanceRepo.search(
          new Criteria(Filters.fromValues([
              new Map([["field", "uniqueKey"], ["operator", Operator.EQUAL], ["value", uniqueKey]])
          ]), Order.none())
      );

      if (existing.length > 0) {
          throw new Error("Instance already generated");
      }

      // Create Transaction
      const template = overrideTemplate || rule.template;
      const txId = new ObjectId().toHexString();
      const tx = Transaction.fromPrimitives({
        id: txId,
        transactionId: txId,
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
        status: "pending", 
        createdAt: new Date(),
        updatedAt: new Date(),
        recurringRuleId: rule.ruleId,
      });
      await this.transactionRepo.upsert(tx);

      // Create Instance Record
      const instanceId = crypto.randomUUID();
      const instanceIdMongo = new ObjectId().toHexString();
      const instance = GeneratedInstance.create(
        instanceIdMongo,
        instanceId,
        rule.ruleId,
        userId,
        date,
        txId,
      );
      await this.instanceRepo.upsert(instance);

      return tx;
  }

  /**
   * Split a recurring rule into two.
   * Used for "Edit This and Future".
   * Ends current rule yesterday, creates new rule starting today.
   */
  async split(userId: string, ruleId: string, splitDate: Date, newTemplate: RecurringRulePrimitives["template"]) {
      const rule = await this.ruleRepo.byId(ruleId);
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
          template: newTemplate,
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
    const paginated = await this.ruleRepo.list(
      new Criteria(
        Filters.fromValues([
          new Map<string, any>([["field", "userId"], ["operator", Operator.EQUAL], ["value", userId]]),
          new Map<string, any>([["field", "active"], ["operator", Operator.EQUAL], ["value", true]]),
        ]),
        Order.none(),
        100, // Reasonable max
        1,
      ),
    );
    return paginated.results;
  }

  private async getInstancesInPeriod(userId: string, start: Date, end: Date) {
    const instances = await this.instanceRepo.search(
      new Criteria(
        Filters.fromValues([
          new Map<string, any>([["field", "userId"], ["operator", Operator.EQUAL], ["value", userId]]),
          new Map<string, any>([["field", "date"], ["operator", Operator.BETWEEN], ["value", { start, end }]]),
        ]),
        Order.none(),
      ),
    );
    return new Set(instances.map((i) => i.toPrimitives().uniqueKey));
  }

  private calculateDates(rule: RecurringRule, windowStart: Date, windowEnd: Date): Date[] {
    const dates: Date[] = [];
    let current = new Date(rule.startDate);

    // If start date is in future beyond window, no dates
    if (current > windowEnd) return [];

    // Advance current to be at least windowStart or close to it
    // For simplicity, we just iterate from startDate. Optimization possible for yearly.
    
    // Safety break
    let safety = 0;
    while (current <= windowEnd && safety < 1000) {
      if (current >= windowStart) {
        dates.push(new Date(current));
      }

      // Advance
      if (rule.frequency === "weekly") {
        current.setDate(current.getDate() + 7 * rule.interval);
      } else if (rule.frequency === "monthly") {
        current.setMonth(current.getMonth() + rule.interval);
      } else if (rule.frequency === "yearly") {
        current.setFullYear(current.getFullYear() + rule.interval);
      }
      safety++;
    }

    return dates;
  }
}
