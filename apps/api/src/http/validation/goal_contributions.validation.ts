import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"

export type GoalContributionCreatePayload = {
  goalId: string
  date?: string | Date
  amount: number
  accountId?: string | null
  note?: string | null
}

export type GoalContributionUpdatePayload =
  Partial<GoalContributionCreatePayload>

const DateLikeSchema = v.union([v.string(), v.date()])

const GoalContributionBaseSchema = v.strictObject({
  goalId: v.pipe(v.string(), v.minLength(1)),
  date: v.optional(DateLikeSchema),
  amount: v.number(),
  accountId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  note: v.optional(v.nullable(v.string())),
})

const GoalContributionCreateSchema = GoalContributionBaseSchema
const GoalContributionUpdateSchema = v.partial(GoalContributionBaseSchema)

export function validateGoalContributionPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body
    const schema = isUpdate
      ? GoalContributionUpdateSchema
      : GoalContributionCreateSchema
    const result = v.safeParse(schema, payload)

    if (!result.success) {
      if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.goalId) return res.status(422).send({ error: "Falta la meta" })
      if (flattened.nested?.amount)
        return res.status(422).send({ error: "Falta el monto" })
      return res.status(422).send({ error: "Payload invalido" })
    }

    const data = payload as { amount?: number; date?: string | Date }
    if (!isUpdate && (data.amount == null || data.amount <= 0)) {
      return res.status(422).send({ error: "El monto debe ser mayor que 0" })
    }

    if (data.date) {
      const date = new Date(data.date)
      if (Number.isNaN(date.getTime()))
        return res.status(422).send({ error: "Fecha invalida" })
    }

    return next()
  }
}
