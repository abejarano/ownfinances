import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import type { BudgetLine, BudgetPeriodType } from "../../models/budget";

export type BudgetCreatePayload = {
  periodType: BudgetPeriodType;
  startDate: string | Date;
  endDate: string | Date;
  lines?: BudgetLine[];
};

export type BudgetUpdatePayload = Partial<BudgetCreatePayload>;

const BudgetPeriodSchema = t.Union([
  t.Literal("monthly"),
  t.Literal("quarterly"),
  t.Literal("semiannual"),
  t.Literal("annual"),
]);

const DateLikeSchema = t.Union([t.String(), t.Date()]);

const BudgetLineSchema = t.Object(
  {
    categoryId: t.String({ minLength: 1 }),
    plannedAmount: t.Number({ minimum: 0 }),
  },
  { additionalProperties: false }
);

const BudgetBaseSchema = t.Object(
  {
    periodType: BudgetPeriodSchema,
    startDate: DateLikeSchema,
    endDate: DateLikeSchema,
    lines: t.Optional(t.Array(BudgetLineSchema)),
  },
  { additionalProperties: false }
);

const BudgetCreateSchema = BudgetBaseSchema;
const BudgetUpdateSchema = t.Partial(BudgetBaseSchema);

const budgetCreateCompiler = TypeCompiler.Compile(BudgetCreateSchema);
const budgetUpdateCompiler = TypeCompiler.Compile(BudgetUpdateSchema);

export function validateBudgetPayload(
  payload: BudgetCreatePayload | BudgetUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate ? budgetUpdateCompiler : budgetCreateCompiler;
  if (!compiler.Check(payload)) {
    const data = payload as {
      periodType?: string;
      startDate?: string | Date;
      endDate?: string | Date;
    };
    if (!isUpdate && !data?.periodType) return "Falta el periodo";

    for (const error of compiler.Errors(payload)) {
      if (error.path === "/periodType") return "Periodo invalido";
      if (error.path === "/startDate") return "Falta la fecha de inicio";
      if (error.path === "/endDate") return "Falta la fecha de fin";
      if (error.path.startsWith("/lines")) {
        return "Lineas invalidas en el presupuesto";
      }
    }
    return "Payload invalido";
  }

  const maybePayload = payload as {
    startDate?: string | Date;
    endDate?: string | Date;
  };
  if (maybePayload.startDate && maybePayload.endDate) {
    const start = new Date(maybePayload.startDate);
    const end = new Date(maybePayload.endDate);
    if (start > end) {
      return "La fecha de fin debe ser mayor a la fecha de inicio";
    }
  }

  return null;
}
