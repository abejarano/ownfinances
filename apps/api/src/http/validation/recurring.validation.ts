import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"
import { TransactionType } from "../../models/transaction"
import { RecurringFrequency } from "../../models/recurring/recurring_rule"

export type RecurringTemplatePayload = {
  type: TransactionType
  amount: number
  currency?: string
  categoryId?: string
  fromAccountId?: string
  toAccountId?: string
  note?: string
  tags?: string[]
}

export type RecurringRuleCreatePayload = {
  frequency: RecurringFrequency
  interval: number
  startDate: string | Date
  endDate?: string | Date
  template: RecurringTemplatePayload
  isActive?: boolean
}

export type RecurringRuleUpdatePayload = Partial<RecurringRuleCreatePayload>

export type RecurringRunQuery = {
  period: "monthly"
  date?: string
}

export type RecurringPreviewQuery = RecurringRunQuery

export type RecurringMaterializePayload = {
  date: string
}

export type RecurringSplitPayload = {
  date: string
  template: RecurringTemplatePayload
}

const TemplateSchema = v.strictObject({
  type: v.enum_(TransactionType),
  amount: v.number(),
  currency: v.optional(v.pipe(v.string(), v.minLength(1))),
  categoryId: v.optional(v.pipe(v.string(), v.minLength(1))),
  fromAccountId: v.optional(v.pipe(v.string(), v.minLength(1))),
  toAccountId: v.optional(v.pipe(v.string(), v.minLength(1))),
  note: v.optional(v.string()),
  tags: v.optional(v.array(v.string())),
})

const RuleSchema = v.strictObject({
  frequency: v.enum_(RecurringFrequency),
  interval: v.pipe(v.number(), v.minValue(1)),
  startDate: v.union([v.string(), v.date()]),
  endDate: v.optional(v.union([v.string(), v.date()])),
  template: TemplateSchema,
  isActive: v.optional(v.boolean()),
})

const RunQuerySchema = v.strictObject({
  period: v.literal("monthly"),
  date: v.optional(v.pipe(v.string(), v.minLength(1))),
})

const MaterializeSchema = v.strictObject({
  date: v.pipe(v.string(), v.minLength(1)),
})

const SplitSchema = v.strictObject({
  date: v.pipe(v.string(), v.minLength(1)),
  template: TemplateSchema,
})

const RuleUpdateSchema = v.partial(RuleSchema)

export function validateRecurringRulePayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const schema = isUpdate ? RuleUpdateSchema : RuleSchema
    const result = v.safeParse(schema, req.body)
    if (!result.success) {
      if (!result.issues) return res.status(422).send("Payload invalido")
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.frequency)
        return res.status(422).send("Frecuencia invalida")
      if (flattened.nested?.interval)
        return res.status(422).send("Intervalo invalido")
      if (flattened.nested?.startDate)
        return res.status(422).send("Falta la fecha de inicio")
      if (flattened.nested?.template)
        return res.status(422).send("Plantilla invalida")
      return res.status(422).send("Payload invalido")
    }
    return next()
  }
}

export function validateRecurringRunQuery() {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const result = v.safeParse(RunQuerySchema, req.query)
    if (!result.success) {
      if (!result.issues) return res.status(422).send("Payload invalido")
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.period)
        return res.status(422).send("Periodo invalido")
      if (flattened.nested?.date) return res.status(422).send("Fecha invalida")
      return res.status(422).send("Payload invalido")
    }
    return next()
  }
}

export function validateRecurringMaterializePayload() {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const result = v.safeParse(MaterializeSchema, req.body)
    if (!result.success) {
      if (!result.issues) return res.status(422).send("Payload invalido")
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.date) return res.status(422).send("Fecha invalida")
      return res.status(422).send("Payload invalido")
    }
    return next()
  }
}

export function validateRecurringSplitPayload() {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const result = v.safeParse(SplitSchema, req.body)
    if (!result.success) {
      if (!result.issues) return res.status(422).send("Payload invalido")
      const flattened = v.flatten(result.issues)
      if (flattened.nested?.date) return res.status(422).send("Fecha invalida")
      if (flattened.nested?.template)
        return res.status(422).send("Plantilla invalida")
      return res.status(422).send("Payload invalido")
    }
    return next()
  }
}
