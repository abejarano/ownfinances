import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "@abejarano/ts-express-server"
import * as v from "valibot"
import { TransactionType } from "../../models/transaction"

export type TemplateCreatePayload = {
  name: string
  type: TransactionType
  amount: number
  currency?: string
  categoryId?: string
  fromAccountId?: string
  toAccountId?: string
  note?: string
  tags?: string[]
}

export type TemplateUpdatePayload = Partial<TemplateCreatePayload>

const TemplateSchema = v.strictObject({
  name: v.pipe(v.string(), v.minLength(1)),
  type: v.enum_(TransactionType),
  amount: v.number(),
  currency: v.optional(v.pipe(v.string(), v.minLength(1))),
  categoryId: v.optional(v.pipe(v.string(), v.minLength(1))),
  fromAccountId: v.optional(v.pipe(v.string(), v.minLength(1))),
  toAccountId: v.optional(v.pipe(v.string(), v.minLength(1))),
  note: v.optional(v.string()),
  tags: v.optional(v.array(v.string())),
})

const TemplateCreateSchema = TemplateSchema
const TemplateUpdateSchema = v.partial(TemplateSchema)

export function validateTemplatePayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const schema = isUpdate ? TemplateUpdateSchema : TemplateCreateSchema
    const result = v.safeParse(schema, req.body)

    if (!result.success) {
      if (!result.issues)
        return res.status(422).send({ error: "Payload invalido" })
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.name)
        return res
          .status(422)
          .send({ error: "Falta el nombre de la plantilla" })
      if (flattened.nested?.type)
        return res.status(422).send({ error: "Tipo de transaccion invalido" })
      if (flattened.nested?.amount)
        return res.status(422).send({ error: "Falta el monto" })
      return res.status(422).send({ error: "Payload invalido" })
    }

    return next()
  }
}
