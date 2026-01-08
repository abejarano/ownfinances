import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { TransactionStatus, TransactionType } from "../../models/transaction";

export type TransactionCreatePayload = {
  type: TransactionType;
  date?: string | Date;
  amount: number;
  currency?: string;
  categoryId?: string | null;
  fromAccountId?: string | null;
  toAccountId?: string | null;
  note?: string | null;
  tags?: string[] | null;
  status?: TransactionStatus;
};

export type TransactionUpdatePayload = Partial<TransactionCreatePayload>;

const TransactionTypeSchema = t.Enum(TransactionType);

const TransactionStatusSchema = t.Enum(TransactionStatus);

const DateLikeSchema = t.Union([t.String(), t.Date()]);

const TransactionBaseSchema = t.Object(
  {
    type: TransactionTypeSchema,
    date: t.Optional(DateLikeSchema),
    amount: t.Number(),
    currency: t.Optional(t.String({ minLength: 1 })),
    categoryId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    fromAccountId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    toAccountId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    note: t.Optional(t.Union([t.String(), t.Null()])),
    tags: t.Optional(t.Union([t.Array(t.String()), t.Null()])),
    status: t.Optional(TransactionStatusSchema),
  },
  { additionalProperties: false }
);

const TransactionCreateSchema = TransactionBaseSchema;
const TransactionUpdateSchema = t.Partial(TransactionBaseSchema);

const transactionCreateCompiler = TypeCompiler.Compile(TransactionCreateSchema);
const transactionUpdateCompiler = TypeCompiler.Compile(TransactionUpdateSchema);

export function validateTransactionPayload(
  payload: TransactionCreatePayload | TransactionUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate
    ? transactionUpdateCompiler
    : transactionCreateCompiler;
  if (!compiler.Check(payload)) {
    const data = payload as {
      type?: string;
      amount?: number;
    };
    if (
      data?.type &&
      !Object.values(TransactionType).includes(data.type as TransactionType)
    ) {
      return "Tipo de transacao invalido";
    }
    if (!isUpdate && !data?.type) {
      return "Falta o tipo de transacao";
    }
    if (!isUpdate && data?.amount === undefined) {
      return "Falta o valor";
    }
    for (const error of compiler.Errors(payload)) {
      if (error.path === "/type") return "Tipo de transacao invalido";
      if (error.path === "/amount") return "Falta o valor";
      if (error.path === "/status") return "Status invalido";
    }
    return "Payload invalido";
  }

  const data = payload as {
    type?: string;
    amount?: number;
    status?: string;
    date?: string | Date;
  };

  if (!isUpdate && !data.type) {
    return "Falta el tipo de transaccion";
  }
  if (
    data.type &&
    !Object.values(TransactionType).includes(data.type as TransactionType)
  ) {
    return "Tipo de transacao invalido";
  }
  if (data.amount !== undefined && data.amount <= 0) {
    return "O valor deve ser maior que 0";
  }
  if (!isUpdate && data.amount === undefined) {
    return "Falta o valor";
  }
  if (
    data.status &&
    !Object.values(TransactionStatus).includes(data.status as TransactionStatus)
  ) {
    return "Status invalido";
  }

  if (data.date) {
    const date = new Date(data.date);
    if (Number.isNaN(date.getTime())) {
      return "Data invalida";
    }
  }

  return null;
}
