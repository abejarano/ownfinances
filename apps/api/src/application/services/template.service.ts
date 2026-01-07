import { Criteria, Filters, Operator, Order } from "@abejarano/ts-mongodb-criteria";
import { ObjectId } from "mongodb";
import * as crypto from "crypto";
import { TransactionTemplate, TransactionTemplatePrimitives, TransactionTemplateRepository } from "../../domain/template/transaction_template";

export class TemplateService {
  constructor(private readonly templateRepo: TransactionTemplateRepository) {}

  async create(userId: string, payload: Omit<TransactionTemplatePrimitives, "id" | "templateId" | "userId" | "createdAt" | "updatedAt">) {
    const id = new ObjectId().toHexString();
    const templateId = crypto.randomUUID();
    const now = new Date();

    const template = TransactionTemplate.fromPrimitives({
      ...payload,
      id,
      templateId,
      userId,
      createdAt: now,
      updatedAt: now,
    });

    await this.templateRepo.upsert(template);
    return template;
  }

  async update(userId: string, templateId: string, payload: Partial<Omit<TransactionTemplatePrimitives, "id" | "templateId" | "userId" | "createdAt" | "updatedAt">>) {
    const template = await this.templateRepo.byId(templateId);
    if (!template || template.userId !== userId) {
        throw new Error("Template not found or access denied");
    }

    const updatedProps = {
        ...template.toPrimitives(),
        ...payload,
        updatedAt: new Date(),
    };

    const updatedTemplate = TransactionTemplate.fromPrimitives(updatedProps);
    await this.templateRepo.upsert(updatedTemplate);
    return updatedTemplate;
  }

  async delete(userId: string, templateId: string) {
    const template = await this.templateRepo.byId(templateId);
    if (!template || template.userId !== userId) return; 
    await this.templateRepo.remove(templateId);
  }

  async list(userId: string, limit = 50, page = 1) {
    return this.templateRepo.list(
      new Criteria(
        Filters.fromValues([
          new Map<string, any>([["field", "userId"], ["operator", Operator.EQUAL], ["value", userId]]),
        ]),
        Order.desc("updatedAt"), // Recently used/updated first
        limit,
        page,
      ),
    );
  }
}
