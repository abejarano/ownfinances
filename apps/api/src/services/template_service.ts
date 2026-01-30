import {
  Criteria,
  Filters,
  Operator,
  Order,
  type Paginate,
} from "@abejarano/ts-mongodb-criteria"
import type { Result } from "../bootstrap/response"
import type {
  TemplateCreatePayload,
  TemplateUpdatePayload,
} from "../http/validation/templates.validation"
import {
  TransactionTemplate,
  type TransactionTemplatePrimitives,
} from "@desquadra/database"
import { TransactionTemplateMongoRepository } from "@desquadra/database"

export class TemplateService {
  constructor(
    private readonly templateRepo: TransactionTemplateMongoRepository
  ) {}

  async create(
    userId: string,
    payload: TemplateCreatePayload
  ): Promise<Result<{ template: TransactionTemplatePrimitives }>> {
    const template = TransactionTemplate.create({
      ...payload,
      userId,
    })

    await this.templateRepo.upsert(template)
    return {
      value: { template: template.toPrimitives() },
      status: 201,
    }
  }

  async update(
    userId: string,
    templateId: string,
    payload: TemplateUpdatePayload
  ): Promise<Result<{ template: TransactionTemplatePrimitives }>> {
    const template = await this.templateRepo.one({ templateId })
    if (!template || template.userId !== userId) {
      return { error: "Plantilla no encontrada", status: 404 }
    }

    const updatedProps = {
      ...template.toPrimitives(),
      ...payload,
      currency: payload.currency ?? template.toPrimitives().currency,
      updatedAt: new Date(),
    }

    const updatedTemplate = TransactionTemplate.fromPrimitives(updatedProps)
    await this.templateRepo.upsert(updatedTemplate)
    return {
      value: { template: updatedTemplate.toPrimitives() },
      status: 200,
    }
  }

  async delete(
    userId: string,
    templateId: string
  ): Promise<Result<{ ok: true }>> {
    const template = await this.templateRepo.one({ templateId })
    if (!template || template.userId !== userId) {
      return { error: "Plantilla no encontrada", status: 404 }
    }

    await this.templateRepo.remove(templateId)
    return { value: { ok: true }, status: 200 }
  }

  async getById(
    userId: string,
    templateId: string
  ): Promise<Result<{ template: TransactionTemplatePrimitives }>> {
    const template = await this.templateRepo.one({ templateId })
    if (!template || template.userId !== userId) {
      return { error: "Plantilla no encontrada", status: 404 }
    }
    return { value: { template: template.toPrimitives() }, status: 200 }
  }

  async list(
    userId: string,
    limit = 50,
    page = 1
  ): Promise<Result<Paginate<any>>> {
    return {
      value: await this.templateRepo.list(
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
      ),
      status: 200,
    }
  }
}
