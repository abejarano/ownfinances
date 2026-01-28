import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"
import type { BudgetDebtPayment, BudgetPeriodType } from "../../models/budget"

export type BudgetCreatePayload = {
  periodType: BudgetPeriodType
  startDate: string | Date
  endDate: string | Date
  categories?: BudgetCategoryPlanPayload[]
  debtPayments?: BudgetDebtPayment[]
}

export type BudgetUpdatePayload = Partial<BudgetCreatePayload>

const BudgetPeriodSchema = v.picklist(["monthly"])

const DateLikeSchema = v.union([v.string(), v.date()])

const BudgetEntrySchema = v.strictObject({
  entryId: v.optional(v.string()),
  amount: v.pipe(v.number(), v.minValue(0)),
  currency: v.pipe(v.string(), v.minLength(3), v.maxLength(5)),
  description: v.optional(v.string()),
  createdAt: v.optional(DateLikeSchema),
})

const BudgetCategorySchema = v.strictObject({
  categoryId: v.pipe(v.string(), v.minLength(1)),
  plannedTotal: v.optional(v.record(v.string(), v.number())),
  entries: v.optional(v.array(BudgetEntrySchema)),
})

const BudgetDebtPaymentSchema = v.strictObject({
  debtId: v.pipe(v.string(), v.minLength(1)),
  plannedAmount: v.pipe(v.number(), v.minValue(0)),
})

const BudgetBaseSchema = v.strictObject({
  periodType: BudgetPeriodSchema,
  startDate: DateLikeSchema,
  endDate: DateLikeSchema,
  categories: v.optional(v.array(BudgetCategorySchema)),
  debtPayments: v.optional(v.array(BudgetDebtPaymentSchema)),
})

const BudgetCreateSchema = BudgetBaseSchema
const BudgetUpdateSchema = v.partial(BudgetBaseSchema)

export function validateBudgetPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body as any

    // Pre-process payload to handle null description coming from Flutter
    if (payload?.categories && Array.isArray(payload.categories)) {
      for (const category of payload.categories) {
        if (category.entries && Array.isArray(category.entries)) {
          for (const entry of category.entries) {
            if (entry.description === null) {
              entry.description = undefined
            }
          }
        }
      }
    }

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

      if (!result.issues)
        return res.status(422).send({ error: "Payload invalido" })
      
      const firstIssue = result.issues[0]
      const path = firstIssue.path?.map((p) => p.key).join(".")
      
      if (path?.includes("periodType"))
        return res.status(422).send({ error: "Periodo invalido" })
      if (path?.includes("startDate"))
        return res.status(422).send({ error: "Falta la fecha de inicio" })
      if (path?.includes("endDate"))
        return res.status(422).send({ error: "Falta la fecha de fin" })
      if (path?.includes("categories"))
        return res
          .status(422)
          .send({ error: `Categorias inválidas: ${firstIssue.message}` })
      if (path?.includes("debtPayments"))
        return res
          .status(422)
          .send({ error: `Pagos de deuda inválidos: ${firstIssue.message}` })

      return res.status(422).send({ error: `Payload invalido: ${firstIssue.message} en ${path}` })
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
          .send({
            error: "La fecha de fin debe ser mayor a la fecha de inicio",
          })
      }
    }

    return next()
  }
}

export type BudgetCategoryPlanPayload = {
  categoryId: string
  plannedTotal?: Record<string, number>
  entries?: Array<{
    entryId?: string
    amount: number
    currency: string
    description?: string
    createdAt?: string | Date
  }>
}
