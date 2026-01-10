import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { AccountType } from "../../models/account";
import { BankType } from "../../models/bank_type";

export type AccountCreatePayload = {
  name: string;
  type: AccountType;
  bankType?: BankType | null;
  currency?: string;
  isActive?: boolean;
};

export type AccountUpdatePayload = Partial<AccountCreatePayload>;

const AccountTypeSchema = t.Enum(AccountType);
const BankTypeSchema = t.Enum(BankType);

const AccountBaseSchema = t.Object(
  {
    name: t.String({ minLength: 1 }),
    type: AccountTypeSchema,
    bankType: t.Optional(t.Union([BankTypeSchema, t.Null()])),
    currency: t.Optional(t.String({ minLength: 1 })),
    isActive: t.Optional(t.Boolean()),
  },
  { additionalProperties: false }
);

const AccountCreateSchema = AccountBaseSchema;
const AccountUpdateSchema = t.Partial(AccountBaseSchema);

const accountCreateCompiler = TypeCompiler.Compile(AccountCreateSchema);
const accountUpdateCompiler = TypeCompiler.Compile(AccountUpdateSchema);

export function validateAccountPayload(
  payload: AccountCreatePayload | AccountUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate ? accountUpdateCompiler : accountCreateCompiler;
  if (compiler.Check(payload)) {
    return null;
  }

  for (const error of compiler.Errors(payload)) {
    if (error.path === "/name") return "Falta o nome da conta";
    if (error.path === "/type") return "Tipo de conta invalido";
    if (error.path === "/currency") return "Moeda invalida";
  }

  return "Payload invalido";
}
