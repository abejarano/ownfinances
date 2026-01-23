import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"
import type { BudgetLine, BudgetPeriodType } from "../../models/budget"

export type BudgetCreatePayload = {
  periodType: BudgetPeriodType
  startDate: string | Date
  endDate: string | Date
  lines?: BudgetLine[]
}

export type BudgetUpdatePayload = Partial<BudgetCreatePayload>

const BudgetPeriodSchema = v.picklist(["monthly"])

const DateLikeSchema = v.union([v.string(), v.date()])

const BudgetLineSchema = v.strictObject({
  categoryId: v.pipe(v.string(), v.minLength(1)),
  plannedAmount: v.pipe(v.number(), v.minValue(0)),
})

const BudgetBaseSchema = v.strictObject({
  periodType: BudgetPeriodSchema,
  startDate: DateLikeSchema,
  endDate: DateLikeSchema,
  lines: v.optional(v.array(BudgetLineSchema)),
})

const BudgetCreateSchema = BudgetBaseSchema
const BudgetUpdateSchema = v.partial(BudgetBaseSchema)

export function validateBudgetPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body

    const schema = isUpdate ? BudgetUpdateSchema : BudgetCreateSchema
    const result = v.safeParse(schema, payload)
    if (!result.success) {
      const data = payload as {
        periodType?: string
        startDate?: string | Date
        endDate?: string | Date
      }
      if (!isUpdate && !data?.periodType)
        return res.status(422).send({ error: "Falta el periodo" })

      if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
      const flattened = v.flatten(result.issues)

      if (flattened.nested?.periodType)
        return res.status(422).send({ error: "Periodo invalido" })
      if (flattened.nested?.startDate)
        return res.status(422).send({ error: "Falta la fecha de inicio" })
      if (flattened.nested?.endDate)
        return res.status(422).send({ error: "Falta la fecha de fin" })
      if (flattened.nested?.lines)
        return res.status(422).send({ error: "Lineas invalidas en el presupuesto" })

      return res.status(422).send({ error: "Payload invalido" })
    }

    const maybePayload = payload as {
      startDate?: string | Date
      endDate?: string | Date
    }
    if (maybePayload.startDate && maybePayload.endDate) {
      const start = new Date(maybePayload.startDate)
      const end = new Date(maybePayload.endDate)
      if (start > end) {
        return res
          .status(422)
          .send({ error: "La fecha de fin debe ser mayor a la fecha de inicio" })
      }
    }

    return next()
  }
}
