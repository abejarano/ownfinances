import { AccountType, BankType } from "@desquadra/database"
import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"

export type AccountCreatePayload = {
  name: string
  type: AccountType
  bankType?: BankType | string | null
  currency?: string
  isActive?: boolean
}

export type AccountUpdatePayload = Partial<AccountCreatePayload>

const AccountBaseSchema = v.strictObject({
  name: v.pipe(v.string(), v.minLength(1)),
  type: v.enum_(AccountType),
  bankType: v.optional(v.nullable(v.union([v.enum_(BankType), v.string()]))),
  currency: v.optional(v.pipe(v.string(), v.minLength(1))),
  isActive: v.optional(v.boolean()),
})

const AccountCreateSchema = AccountBaseSchema
const AccountUpdateSchema = v.partial(AccountBaseSchema)

export function validateAccountPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const schema = isUpdate ? AccountUpdateSchema : AccountCreateSchema
    const result = v.safeParse(schema, req.body)
    if (result.success) {
      return next()
    }
    if (!result.issues) {
      return res.status(422).send({ error: "Payload invalido" })
    }

    const flattened = v.flatten(result.issues)

    // Handle nested issues (likely what happens with `flatten` here)
    if (flattened.nested) {
      if (flattened.nested.name)
        return res.status(422).send({ error: "Falta o nome da conta" })
      if (flattened.nested.type)
        return res.status(422).send({ error: "Tipo de conta invalido" })
      if (flattened.nested.currency)
        return res.status(422).send({ error: "Moeda invalida" })
      if (flattened.nested.bankType)
        return res.status(422).send({ error: "Banco inválido" })
    }

    return res.status(422).send({ error: "Payload invalido" })
  }
}
