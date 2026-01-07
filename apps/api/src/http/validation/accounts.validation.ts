import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { AccountType } from "../../models/account";

export type AccountCreatePayload = {
  name: string;
  type: AccountType;
  currency?: string;
  isActive?: boolean;
};

export type AccountUpdatePayload = Partial<AccountCreatePayload>;

const AccountTypeSchema = t.Enum(AccountType);

const AccountBaseSchema = t.Object(
  {
    name: t.String({ minLength: 1 }),
    type: AccountTypeSchema,
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
    if (error.path === "/name") return "Falta el nombre de la cuenta";
    if (error.path === "/type") return "Tipo de cuenta invalido";
    if (error.path === "/currency") return "Moneda invalida";
  }

  return "Payload invalido";
}
