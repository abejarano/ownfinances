import { DebtTransactionType } from "@desquadra/database"
import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"

export type DebtTransactionCreatePayload = {
  debtId: string
  date?: string | Date
  type: DebtTransactionType
  amount: number
  accountId?: string | null
  categoryId?: string | null
  note?: string | null
}

export type DebtTransactionUpdatePayload = Partial<DebtTransactionCreatePayload>

const DebtTransactionTypeSchema = v.picklist([
  DebtTransactionType.Charge,
  DebtTransactionType.Payment,
  DebtTransactionType.Fee,
  DebtTransactionType.Interest,
])
const DateLikeSchema = v.union([v.string(), v.date()])

const DebtTransactionBaseSchema = v.strictObject({
  debtId: v.pipe(v.string(), v.minLength(1)),
  date: v.optional(DateLikeSchema),
  type: DebtTransactionTypeSchema,
  amount: v.number(),
  accountId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  categoryId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  note: v.optional(v.nullable(v.string())),
})

const DebtTransactionCreateSchema = DebtTransactionBaseSchema
const DebtTransactionUpdateSchema = v.partial(DebtTransactionBaseSchema)

export function validateDebtTransactionPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body
    const schema = isUpdate
      ? DebtTransactionUpdateSchema
      : DebtTransactionCreateSchema
    const result = v.safeParse(schema, payload)

    if (!result.success) {
      const flattened = v.flatten(result.issues)

      if (flattened.nested?.debtId)
        return res.status(422).json({ error: "Falta la deuda" })
      if (flattened.nested?.type)
        return res.status(422).json({ error: "Tipo invalido" })
      if (flattened.nested?.amount)
        return res.status(422).json({ error: "Falta el monto" })

      const paramError = flattened.nested
        ? Object.values(flattened.nested)[0]?.[0]
        : "Payload invalido"
      return res.status(422).json({ error: paramError })
    }

    const data = payload as {
      amount?: number
      type?: string
      date?: string | Date
    }

    if (!isUpdate && !data.type) {
      return res.status(422).json({ error: "Falta el tipo" })
    }

    if (data.amount !== undefined && data.amount <= 0) {
      return res.status(422).json({ error: "El monto debe ser mayor que 0" })
    }

    if (!isUpdate && data.amount === undefined) {
      return res.status(422).json({ error: "Falta el monto" })
    }

    if (
      data.type &&
      !Object.values(DebtTransactionType).includes(
        data.type as DebtTransactionType
      )
    ) {
      return res.status(422).json({ error: "Tipo invalido" })
    }

    if (data.date) {
      const date = new Date(data.date)
      if (Number.isNaN(date.getTime())) {
        return res.status(422).json({ error: "Fecha invalida" })
      }
    }

    // Validar que charge tenga categoría
    if (!isUpdate && data.type === DebtTransactionType.Charge) {
      const payloadWithCategory = payload as { categoryId?: string | null }
      if (!payloadWithCategory.categoryId) {
        return res
          .status(422)
          .json({ error: "Falta la categoria para la compra" })
      }
    }

    return next()
  }
}
