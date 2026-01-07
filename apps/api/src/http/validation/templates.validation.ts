import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { TransactionType } from "../../models/transaction";

export type TemplateCreatePayload = {
  name: string;
  type: TransactionType;
  amount: number;
  currency?: string;
  categoryId?: string;
  fromAccountId?: string;
  toAccountId?: string;
  note?: string;
  tags?: string[];
};

export type TemplateUpdatePayload = Partial<TemplateCreatePayload>;

const TemplateSchema = t.Object(
  {
    name: t.String({ minLength: 1 }),
    type: t.Enum(TransactionType),
    amount: t.Number(),
    currency: t.Optional(t.String({ minLength: 1 })),
    categoryId: t.Optional(t.String({ minLength: 1 })),
    fromAccountId: t.Optional(t.String({ minLength: 1 })),
    toAccountId: t.Optional(t.String({ minLength: 1 })),
    note: t.Optional(t.String()),
    tags: t.Optional(t.Array(t.String())),
  },
  { additionalProperties: false },
);

const TemplateCreateSchema = TemplateSchema;
const TemplateUpdateSchema = t.Partial(TemplateSchema);

const templateCreateCompiler = TypeCompiler.Compile(TemplateCreateSchema);
const templateUpdateCompiler = TypeCompiler.Compile(TemplateUpdateSchema);

export function validateTemplatePayload(
  payload: TemplateCreatePayload | TemplateUpdatePayload,
  isUpdate: boolean,
): string | null {
  const compiler = isUpdate ? templateUpdateCompiler : templateCreateCompiler;
  if (compiler.Check(payload)) {
    return null;
  }

  for (const error of compiler.Errors(payload)) {
    if (error.path === "/name") return "Falta el nombre de la plantilla";
    if (error.path === "/type") return "Tipo de transaccion invalido";
    if (error.path === "/amount") return "Falta el monto";
  }

  return "Payload invalido";
}
