import type { TemplateService } from "../../services/template_service";
import { TransactionTemplate } from "../../models/template/transaction_template";
import { notFound } from "../errors";
import type {
  TemplateCreatePayload,
  TemplateUpdatePayload,
} from "../validation/templates.validation";

export class TemplatesController {
  constructor(private readonly service: TemplateService) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const limit = query.limit ? Number(query.limit) : 50;
    const page = query.page ? Number(query.page) : 1;
    const result = await this.service.list(userId ?? "", limit, page);
    return {
      ...result,
      results: result.results.map((item) =>
        TransactionTemplate.fromPrimitives(item).toPrimitives(),
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: TemplateCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { template } = await this.service.create(userId ?? "", body);
    return template;
  }

  async getById({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const result = await this.service.getById(userId ?? "", params.id);
    if ("error" in result) return notFound(set, result.error);
    return result.template;
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: TemplateUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const result = await this.service.update(userId ?? "", params.id, body);
    if ("error" in result) return notFound(set, result.error);
    return result.template;
  }

  async remove({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const result = await this.service.delete(userId ?? "", params.id);
    if (result?.error) return notFound(set, result.error);
    return { ok: true };
  }
}
