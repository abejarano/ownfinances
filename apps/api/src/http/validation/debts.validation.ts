import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"
import { DebtType } from "../../models/debt"

export type DebtCreatePayload = {
  name: string
  type: DebtType
  linkedAccountId?: string
  paymentAccountId?: string
  currency?: string
  dueDay?: number
  minimumPayment?: number
  interestRateAnnual?: number
  initialBalance?: number
  isActive?: boolean
}

export type DebtUpdatePayload = Partial<DebtCreatePayload>

const DebtTypeSchema = v.picklist([
  DebtType.CreditCard,
  DebtType.Loan,
  DebtType.Other,
])

const DebtBaseSchema = v.strictObject({
  name: v.pipe(v.string(), v.minLength(1)),
  type: DebtTypeSchema,
  linkedAccountId: v.optional(v.string()), // Required logically for CC, but optional in schema to allow other types
  paymentAccountId: v.optional(v.string()),
  currency: v.optional(v.pipe(v.string(), v.minLength(1))),
  dueDay: v.optional(v.number()),
  minimumPayment: v.optional(v.number()),
  interestRateAnnual: v.optional(v.number()),
  initialBalance: v.optional(v.number()),
  isActive: v.optional(v.boolean()),
})

const DebtCreateSchema = DebtBaseSchema
const DebtUpdateSchema = v.partial(DebtBaseSchema)

export function validateDebtPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body

    const schema = isUpdate ? DebtUpdateSchema : DebtCreateSchema
    const result = v.safeParse(schema, payload)

    console.log(result)

    if (result.success) {
      return next()
    }

    const flattened = v.flatten(result.issues)
    if (flattened.nested?.name)
      return res.status(422).send({ error: "Falta el nombre" })

    if (flattened.nested?.type)
      return res.status(422).send({ error: "Tipo de deuda invalido" })

    if (flattened.nested?.currency)
      return res.status(422).send({ error: "Moneda invalida" })

    const validatedData = payload as DebtCreatePayload

    // Logic Rule: Credit Card MUST have linkedAccountId
    if (
      validatedData.type === DebtType.CreditCard &&
      !validatedData.linkedAccountId &&
      !isUpdate
    ) {
      return res
        .status(422)
        .send({ error: "Cartão de crédito deve ter uma conta vinculada" })
    }

    const data = payload as {
      dueDay?: number
      minimumPayment?: number
      interestRateAnnual?: number
    }

    if (data.dueDay !== undefined) {
      if (data.dueDay < 1 || data.dueDay > 31) {
        return res.status(422).send({ error: "Dia de vencimiento invalido" })
      }
    }

    if (data.minimumPayment !== undefined && data.minimumPayment < 0) {
      return res
        .status(422)
        .send({ error: "El minimo debe ser mayor o igual a 0" })
    }

    if (data.interestRateAnnual !== undefined && data.interestRateAnnual < 0) {
      return res
        .status(422)
        .send({ error: "La tasa debe ser mayor o igual a 0" })
    }

    // @ts-ignore
    if (
      validatedData.initialBalance !== undefined &&
      validatedData.initialBalance < 0
    ) {
      return res
        .status(422)
        .send({ error: "El saldo inicial debe ser mayor o igual a 0" })
    }

    return next()
  }
}
