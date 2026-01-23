import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"

export type GoalCreatePayload = {
  name: string
  targetAmount: number
  currency?: string
  startDate: string | Date
  targetDate?: string | Date
  monthlyContribution?: number
  linkedAccountId?: string
  isActive?: boolean
}

export type GoalUpdatePayload = Partial<GoalCreatePayload>

const DateLikeSchema = v.union([v.string(), v.date()])

const GoalBaseSchema = v.strictObject({
  name: v.pipe(v.string(), v.minLength(1)),
  targetAmount: v.number(),
  currency: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  startDate: DateLikeSchema,
  targetDate: v.optional(v.nullable(DateLikeSchema)),
  monthlyContribution: v.optional(v.nullable(v.number())),
  linkedAccountId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  isActive: v.optional(v.boolean()),
})

const GoalCreateSchema = GoalBaseSchema
const GoalUpdateSchema = v.partial(GoalBaseSchema)

export function validateGoalPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body
    const schema = isUpdate ? GoalUpdateSchema : GoalCreateSchema
    const result = v.safeParse(schema, payload)

    if (!result.success) {
      if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.name) return res.status(422).send({ error: "Falta el nombre" })
      if (flattened.nested?.targetAmount)
        return res.status(422).send({ error: "Falta el monto objetivo" })
      if (flattened.nested?.currency)
        return res.status(422).send({ error: "Moneda invalida" })
      if (flattened.nested?.startDate)
        return res.status(422).send({ error: "Fecha invalida" })
      return res.status(422).send({ error: "Payload invalido" })
    }

    const data = payload as {
      targetAmount?: number
      monthlyContribution?: number | null
      startDate?: string | Date
      targetDate?: string | Date | null
    }

    if (!isUpdate && (data.targetAmount == null || data.targetAmount <= 0)) {
      return res.status(422).send({ error: "El monto debe ser mayor que 0" })
    }
    if (data.monthlyContribution != null && data.monthlyContribution < 0) {
      return res.status(422).send({ error: "El aporte debe ser mayor o igual a 0" })
    }

    if (data.startDate) {
      const date = new Date(data.startDate)
      if (Number.isNaN(date.getTime()))
        return res.status(422).send({ error: "Fecha invalida" })
    }
    if (data.targetDate) {
      const date = new Date(data.targetDate)
      if (Number.isNaN(date.getTime()))
        return res.status(422).send({ error: "Fecha invalida" })
    }

    return next()
  }
}
