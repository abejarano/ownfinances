import type { RecurringService } from "../../application/services/recurring.service";

export class RecurringController {
  constructor(private readonly service: RecurringService) {}

  async create(ctx: { userId: string; body: any }) {
    const { body, userId } = ctx;
    const rule = await this.service.create(userId, {
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
    return rule.toPrimitives();
  }

  async list(ctx: { userId: string; query: { limit?: string; page?: string } }) {
    const limit = Number(ctx.query.limit || 50);
    const page = Number(ctx.query.page || 1);
    const paginated = await this.service.list(ctx.userId, limit, page);
    return {
      ...paginated,
      results: paginated.results.map(r => r.toPrimitives())
    };
  }

  async delete(ctx: { userId: string; params: { id: string } }) {
    await this.service.delete(ctx.userId, ctx.params.id);
    return { success: true };
  }

  async preview(ctx: { userId: string; query: { period: string; date?: string } }) {
    const period = (ctx.query.period as "monthly") || "monthly";
    const date = ctx.query.date ? new Date(ctx.query.date) : new Date();
    return this.service.preview(ctx.userId, period, date);
  }

  async run(ctx: { userId: string; body: { period: string; date?: string } }) {
    const period = (ctx.body.period as "monthly") || "monthly";
    const date = ctx.body.date ? new Date(ctx.body.date) : new Date();
    return this.service.run(ctx.userId, period, date);
  }

  async materialize(ctx: { userId: string; params: { id: string }; body: { date: string } }) {
    const date = new Date(ctx.body.date);
    const tx = await this.service.materialize(ctx.userId, ctx.params.id, date);
    return tx.toPrimitives();
  }

  async split(ctx: { userId: string; params: { id: string }; body: { date: string; template: any } }) {
    const date = new Date(ctx.body.date);
    const template = ctx.body.template;
    const rule = await this.service.split(ctx.userId, ctx.params.id, date, template);
    return rule.toPrimitives();
  }
}
