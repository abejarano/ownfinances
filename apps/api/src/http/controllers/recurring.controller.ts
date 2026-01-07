import type { RecurringService } from "../../services/recurring_service";

export class RecurringController {
  constructor(private readonly service: RecurringService) {}

  async create(ctx: { userId: string; body: any }) {
    const { body, userId } = ctx;
    const { rule } = await this.service.create(userId, {
      frequency: body.frequency,
      interval: body.interval || 1,
      startDate: new Date(body.startDate),
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      template: {
        type: body.template.type,
        amount: Number(body.template.amount),
        currency: body.template.currency || "BRL",
        categoryId: body.template.categoryId,
        fromAccountId: body.template.fromAccountId,
        toAccountId: body.template.toAccountId,
        note: body.template.note,
        tags: body.template.tags,
      },
    });
    return rule;
  }

  async list(ctx: {
    userId: string;
    query: { limit?: string; page?: string };
  }) {
    const limit = Number(ctx.query.limit || 50);
    const page = Number(ctx.query.page || 1);
    const paginated = await this.service.list(ctx.userId, limit, page);
    return {
      ...paginated,
      results: paginated.results.map((r) => r.toPrimitives()),
    };
  }

  async getById(ctx: { userId: string; params: { id: string } }) {
    return this.service.getById(ctx.userId, ctx.params.id);
  }

  async update(ctx: { userId: string; params: { id: string }; body: any }) {
    const { body } = ctx;
    return this.service.update(ctx.userId, ctx.params.id, {
      frequency: body.frequency,
      interval: body.interval,
      startDate: body.startDate ? new Date(body.startDate) : undefined,
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      isActive: body.isActive,
      template: body.template
        ? {
            type: body.template.type,
            amount: Number(body.template.amount),
            currency: body.template.currency || "BRL",
            categoryId: body.template.categoryId,
            fromAccountId: body.template.fromAccountId,
            toAccountId: body.template.toAccountId,
            note: body.template.note,
            tags: body.template.tags,
          }
        : undefined,
    });
  }

  async delete(ctx: { userId: string; params: { id: string } }) {
    await this.service.delete(ctx.userId, ctx.params.id);
    return { success: true };
  }

  async preview(ctx: {
    userId: string;
    query: { period: string; date?: string };
  }) {
    const period = (ctx.query.period as "monthly") || "monthly";
    const date = ctx.query.date ? new Date(ctx.query.date) : new Date();
    return this.service.preview(ctx.userId, period, date);
  }

  async run(ctx: {
    userId: string;
    body?: { period?: string; date?: string };
    query?: { period?: string; date?: string };
  }) {
    const queryPeriod = (ctx as { query?: { period?: string } }).query?.period;
    const queryDate = (ctx as { query?: { date?: string } }).query?.date;
    const period =
      (queryPeriod as "monthly") ||
      (ctx.body?.period as "monthly") ||
      "monthly";
    const date = queryDate
      ? new Date(queryDate)
      : ctx.body?.date
      ? new Date(ctx.body.date)
      : new Date();
    return this.service.run(ctx.userId, period, date);
  }

  async materialize(ctx: {
    userId: string;
    params: { id: string };
    body: { date: string };
  }) {
    const date = new Date(ctx.body.date);
    const tx = await this.service.materialize(ctx.userId, ctx.params.id, date);
    return tx.toPrimitives();
  }

  async split(ctx: {
    userId: string;
    params: { id: string };
    body: { date: string; template: any };
  }) {
    const date = new Date(ctx.body.date);
    const template = ctx.body.template;
    const { rule } = await this.service.split(
      ctx.userId,
      ctx.params.id,
      date,
      template
    );
    return rule;
  }
}
