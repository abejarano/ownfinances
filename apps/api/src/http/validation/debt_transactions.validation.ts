import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { DebtTransactionType } from "../../models/debt_transaction";

export type DebtTransactionCreatePayload = {
  debtId: string;
  date?: string | Date;
  type: DebtTransactionType;
  amount: number;
  accountId?: string | null;
  note?: string | null;
};

export type DebtTransactionUpdatePayload = Partial<DebtTransactionCreatePayload>;

const DebtTransactionTypeSchema = t.Enum(DebtTransactionType);
const DateLikeSchema = t.Union([t.String(), t.Date()]);

const DebtTransactionBaseSchema = t.Object(
  {
    debtId: t.String({ minLength: 1 }),
    date: t.Optional(DateLikeSchema),
    type: DebtTransactionTypeSchema,
    amount: t.Number(),
    accountId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    note: t.Optional(t.Union([t.String(), t.Null()])),
  },
  { additionalProperties: false }
);

const DebtTransactionCreateSchema = DebtTransactionBaseSchema;
const DebtTransactionUpdateSchema = t.Partial(DebtTransactionBaseSchema);

const debtTransactionCreateCompiler = TypeCompiler.Compile(
  DebtTransactionCreateSchema
);
const debtTransactionUpdateCompiler = TypeCompiler.Compile(
  DebtTransactionUpdateSchema
);

export function validateDebtTransactionPayload(
  payload: DebtTransactionCreatePayload | DebtTransactionUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate
    ? debtTransactionUpdateCompiler
    : debtTransactionCreateCompiler;

  if (!compiler.Check(payload)) {
    for (const error of compiler.Errors(payload)) {
      if (error.path === "/debtId") return "Falta la deuda";
      if (error.path === "/type") return "Tipo invalido";
      if (error.path === "/amount") return "Falta el monto";
    }
    return "Payload invalido";
  }

  const data = payload as {
    amount?: number;
    type?: string;
    date?: string | Date;
  };

  if (!isUpdate && !data.type) {
    return "Falta el tipo";
  }

  if (data.amount !== undefined && data.amount <= 0) {
    return "El monto debe ser mayor que 0";
  }

  if (!isUpdate && data.amount === undefined) {
    return "Falta el monto";
  }

  if (data.type &&
      !Object.values(DebtTransactionType).includes(
        data.type as DebtTransactionType
      )) {
    return "Tipo invalido";
  }

  if (data.date) {
    const date = new Date(data.date);
    if (Number.isNaN(date.getTime())) {
      return "Fecha invalida";
    }
  }

  return null;
}
