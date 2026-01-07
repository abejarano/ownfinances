import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";

export type GoalCreatePayload = {
  name: string;
  targetAmount: number;
  currency?: string;
  startDate: string | Date;
  targetDate?: string | Date;
  monthlyContribution?: number;
  linkedAccountId?: string;
  isActive?: boolean;
};

export type GoalUpdatePayload = Partial<GoalCreatePayload>;

const DateLikeSchema = t.Union([t.String(), t.Date()]);

const GoalBaseSchema = t.Object(
  {
    name: t.String({ minLength: 1 }),
    targetAmount: t.Number(),
    currency: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    startDate: DateLikeSchema,
    targetDate: t.Optional(t.Union([DateLikeSchema, t.Null()])),
    monthlyContribution: t.Optional(t.Union([t.Number(), t.Null()])),
    linkedAccountId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    isActive: t.Optional(t.Boolean()),
  },
  { additionalProperties: false }
);

const GoalCreateSchema = GoalBaseSchema;
const GoalUpdateSchema = t.Partial(GoalBaseSchema);

const goalCreateCompiler = TypeCompiler.Compile(GoalCreateSchema);
const goalUpdateCompiler = TypeCompiler.Compile(GoalUpdateSchema);

export function validateGoalPayload(
  payload: GoalCreatePayload | GoalUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate ? goalUpdateCompiler : goalCreateCompiler;
  if (!compiler.Check(payload)) {
    for (const error of compiler.Errors(payload)) {
      if (error.path === "/name") return "Falta el nombre";
      if (error.path === "/targetAmount") return "Falta el monto objetivo";
      if (error.path === "/currency") return "Moneda invalida";
      if (error.path === "/startDate") return "Fecha invalida";
    }
    return "Payload invalido";
  }

  const data = payload as {
    targetAmount?: number;
    monthlyContribution?: number;
    startDate?: string | Date;
    targetDate?: string | Date;
  };

  if (!isUpdate && (data.targetAmount == null || data.targetAmount <= 0)) {
    return "El monto debe ser mayor que 0";
  }
  if (data.monthlyContribution != null && data.monthlyContribution < 0) {
    return "El aporte debe ser mayor o igual a 0";
  }

  if (data.startDate) {
    const date = new Date(data.startDate);
    if (Number.isNaN(date.getTime())) return "Fecha invalida";
  }
  if (data.targetDate) {
    const date = new Date(data.targetDate);
    if (Number.isNaN(date.getTime())) return "Fecha invalida";
  }

  return null;
}
