import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "@abejarano/ts-express-server"
import * as v from "valibot"
import { TransactionStatus, TransactionType } from "../../models/transaction"

export type TransactionCreatePayload = {
  type: TransactionType
  date?: string | Date
  amount: number
  destinationAmount?: number | null
  currency?: string
  categoryId?: string | null
  fromAccountId?: string | null
  toAccountId?: string | null
  note?: string | null
  tags?: string[] | null
  status?: TransactionStatus
}

export type TransactionUpdatePayload = Partial<TransactionCreatePayload>

const TransactionTypeSchema = v.enum_(TransactionType)

const TransactionStatusSchema = v.enum_(TransactionStatus)

const DateLikeSchema = v.union([v.string(), v.date()])

const TransactionBaseSchema = v.strictObject({
  type: TransactionTypeSchema,
  date: v.optional(DateLikeSchema),
  amount: v.number(),
  destinationAmount: v.optional(v.nullable(v.number())),
  currency: v.optional(v.pipe(v.string(), v.minLength(1))),
  categoryId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  fromAccountId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  toAccountId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  note: v.optional(v.nullable(v.string())),
  tags: v.optional(v.nullable(v.array(v.string()))),
  status: v.optional(TransactionStatusSchema),
})

const TransactionCreateSchema = TransactionBaseSchema
const TransactionUpdateSchema = v.partial(TransactionBaseSchema)

export function validateTransactionPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const schema = isUpdate ? TransactionUpdateSchema : TransactionCreateSchema
    const result = v.safeParse(schema, req.body)

    if (!result.success) {
      const data = req.body as {
        type?: string
        amount?: number
        status?: string
      }
      if (
        data?.type &&
        !Object.values(TransactionType).includes(data.type as TransactionType)
      ) {
        return res.status(422).send({ error: "Tipo de transacao invalido" })
      }
      if (!isUpdate && !data?.type) {
        return res.status(422).send({ error: "Falta o tipo de transacao" })
      }
      if (!isUpdate && data?.amount === undefined) {
        return res.status(422).send({ error: "Falta o valor" })
      }
      if (
        data?.status &&
        !Object.values(TransactionStatus).includes(
          data.status as TransactionStatus
        )
      ) {
        return res.status(422).send({ error: "Status invalido" })
      }
      if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.type)
        return res.status(422).send({ error: "Tipo de transacao invalido" })
      if (flattened.nested?.amount)
        return res.status(422).send({ error: "Falta o valor" })
      if (flattened.nested?.status)
        return res.status(422).send({ error: "Status invalido" })

      const details = Object.entries(flattened.nested || {})
        .map(([key, msgs]) => `${key}: ${msgs?.join(", ")}`)
        .join("; ")
      return res.status(422).send({ error: `Payload invalido: ${details}` })
    }

    const data = req.body as {
      type?: string
      amount?: number
      status?: string
      date?: string | Date
    }

    if (!isUpdate && !data.type) {
      return res.status(422).send({ error: "Falta o tipo de transacao" })
    }
    if (data.amount !== undefined && data.amount <= 0) {
      return res.status(422).send({ error: "O valor deve ser maior que 0" })
    }
    if (!isUpdate && data.amount === undefined) {
      return res.status(422).send({ error: "Falta o valor" })
    }
    if (
      data.status &&
      !Object.values(TransactionStatus).includes(
        data.status as TransactionStatus
      )
    ) {
      return res.status(422).send({ error: "Status invalido" })
    }

    if (data.date) {
      const date = new Date(data.date)
      if (Number.isNaN(date.getTime())) {
        return res.status(422).send({ error: "Data invalida" })
      }
    }

    return next()
  }
}
