import type { ReportsService } from "../../application/services/reports_service";
import type { BudgetPeriodType } from "../../domain/budget";
import { badRequest } from "../errors";

export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  summary = async ({ query, userId, set }: { query: Record<string, string | undefined>; userId?: string; set: { status: number } }) => {
    const period = query.period as BudgetPeriodType | undefined;
    const date = query.date ? new Date(query.date) : new Date();
    if (!period) return badRequest(set, "Falta el periodo");
    if (Number.isNaN(date.getTime())) return badRequest(set, "Fecha invalida");

    return this.reports.summary(userId ?? "", period, date);
  };
}
