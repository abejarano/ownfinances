import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";

export type GoalContributionCreatePayload = {
  goalId: string;
  date?: string | Date;
  amount: number;
  accountId?: string | null;
  note?: string | null;
};

export type GoalContributionUpdatePayload = Partial<GoalContributionCreatePayload>;

const DateLikeSchema = t.Union([t.String(), t.Date()]);

const GoalContributionBaseSchema = t.Object(
  {
    goalId: t.String({ minLength: 1 }),
    date: t.Optional(DateLikeSchema),
    amount: t.Number(),
    accountId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    note: t.Optional(t.Union([t.String(), t.Null()])),
  },
  { additionalProperties: false }
);

const GoalContributionCreateSchema = GoalContributionBaseSchema;
const GoalContributionUpdateSchema = t.Partial(GoalContributionBaseSchema);

const goalContributionCreateCompiler = TypeCompiler.Compile(
  GoalContributionCreateSchema
);
const goalContributionUpdateCompiler = TypeCompiler.Compile(
  GoalContributionUpdateSchema
);

export function validateGoalContributionPayload(
  payload: GoalContributionCreatePayload | GoalContributionUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate
    ? goalContributionUpdateCompiler
    : goalContributionCreateCompiler;

  if (!compiler.Check(payload)) {
    for (const error of compiler.Errors(payload)) {
      if (error.path === "/goalId") return "Falta la meta";
      if (error.path === "/amount") return "Falta el monto";
    }
    return "Payload invalido";
  }

  const data = payload as { amount?: number; date?: string | Date };
  if (!isUpdate && (data.amount == null || data.amount <= 0)) {
    return "El monto debe ser mayor que 0";
  }

  if (data.date) {
    const date = new Date(data.date);
    if (Number.isNaN(date.getTime())) return "Fecha invalida";
  }

  return null;
}
