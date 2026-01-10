import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { DebtType } from "../../models/debt";

export type DebtCreatePayload = {
  name: string;
  type: DebtType;
  linkedAccountId?: string;
  currency?: string;
  dueDay?: number;
  minimumPayment?: number;
  interestRateAnnual?: number;
  isActive?: boolean;
};

export type DebtUpdatePayload = Partial<DebtCreatePayload>;

const DebtTypeSchema = t.Enum(DebtType);

const DebtBaseSchema = t.Object(
  {
    name: t.String({ minLength: 1 }),
    type: DebtTypeSchema,
    linkedAccountId: t.Optional(t.String()),
    currency: t.Optional(t.String({ minLength: 1 })),
    dueDay: t.Optional(t.Number()),
    minimumPayment: t.Optional(t.Number()),
    interestRateAnnual: t.Optional(t.Number()),
    isActive: t.Optional(t.Boolean()),
  },
  { additionalProperties: false }
);

const DebtCreateSchema = DebtBaseSchema;
const DebtUpdateSchema = t.Partial(DebtBaseSchema);

const debtCreateCompiler = TypeCompiler.Compile(DebtCreateSchema);
const debtUpdateCompiler = TypeCompiler.Compile(DebtUpdateSchema);

export function validateDebtPayload(
  payload: DebtCreatePayload | DebtUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate ? debtUpdateCompiler : debtCreateCompiler;
  if (!compiler.Check(payload)) {
    for (const error of compiler.Errors(payload)) {
      if (error.path === "/name") return "Falta el nombre";
      if (error.path === "/type") return "Tipo de deuda invalido";
      if (error.path === "/currency") return "Moneda invalida";
    }
    return "Payload invalido";
  }

  const data = payload as {
    dueDay?: number;
    minimumPayment?: number;
    interestRateAnnual?: number;
  };

  if (data.dueDay !== undefined) {
    if (data.dueDay < 1 || data.dueDay > 31) {
      return "Dia de vencimiento invalido";
    }
  }

  if (data.minimumPayment !== undefined && data.minimumPayment < 0) {
    return "El minimo debe ser mayor o igual a 0";
  }

  if (data.interestRateAnnual !== undefined && data.interestRateAnnual < 0) {
    return "La tasa debe ser mayor o igual a 0";
  }

  return null;
}
