import {
  Criteria,
  Filters,
  Operator,
  Order,
} from "@abejarano/ts-mongodb-criteria";
import { TransactionTemplate } from "../models/template/transaction_template";
import type {
  TemplateCreatePayload,
  TemplateUpdatePayload,
} from "../http/validation/templates.validation";
import { TransactionTemplateMongoRepository } from "../repositories/transaction_template_repository";

export class TemplateService {
  constructor(
    private readonly templateRepo: TransactionTemplateMongoRepository
  ) {}

  async create(userId: string, payload: TemplateCreatePayload) {
    const template = TransactionTemplate.create({
      ...payload,
      userId,
    });

    await this.templateRepo.upsert(template);
    return { template: template.toPrimitives() };
  }

  async update(
    userId: string,
    templateId: string,
    payload: TemplateUpdatePayload
  ) {
    const template = await this.templateRepo.one({ templateId });
    if (!template || template.userId !== userId) {
      return { error: "Plantilla no encontrada", status: 404 };
    }

    const updatedProps = {
      ...template.toPrimitives(),
      ...payload,
      currency: payload.currency ?? template.toPrimitives().currency,
      updatedAt: new Date(),
    };

    const updatedTemplate = TransactionTemplate.fromPrimitives(updatedProps);
    await this.templateRepo.upsert(updatedTemplate);
    return { template: updatedTemplate.toPrimitives() };
  }

  async delete(userId: string, templateId: string) {
    const template = await this.templateRepo.one({ templateId });
    if (!template || template.userId !== userId) {
      return { error: "Plantilla no encontrada", status: 404 };
    }
    await this.templateRepo.remove(templateId);
    return { ok: true };
  }

  async getById(userId: string, templateId: string) {
    const template = await this.templateRepo.one({ templateId });
    if (!template || template.userId !== userId) {
      return { error: "Plantilla no encontrada", status: 404 };
    }
    return { template: template.toPrimitives() };
  }

  async list(userId: string, limit = 50, page = 1) {
    return this.templateRepo.list(
      new Criteria(
        Filters.fromValues([
          new Map<string, any>([
            ["field", "userId"],
            ["operator", Operator.EQUAL],
            ["value", userId],
          ]),
        ]),
        Order.desc("updatedAt"), // Recently used/updated first
        limit,
        page
      )
    );
  }
}
