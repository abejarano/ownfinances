import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import { TransactionType } from "../../models/transaction";
import { RecurringFrequency } from "../../models/recurring/recurring_rule";

export type RecurringTemplatePayload = {
  type: TransactionType;
  amount: number;
  currency?: string;
  categoryId?: string;
  fromAccountId?: string;
  toAccountId?: string;
  note?: string;
  tags?: string[];
};

export type RecurringRuleCreatePayload = {
  frequency: RecurringFrequency;
  interval: number;
  startDate: string | Date;
  endDate?: string | Date;
  template: RecurringTemplatePayload;
  isActive?: boolean;
};

export type RecurringRuleUpdatePayload = Partial<RecurringRuleCreatePayload>;

export type RecurringRunQuery = {
  period: "monthly";
  date?: string;
};

export type RecurringPreviewQuery = RecurringRunQuery;

export type RecurringMaterializePayload = {
  date: string;
};

export type RecurringSplitPayload = {
  date: string;
  template: RecurringTemplatePayload;
};

const TemplateSchema = t.Object(
  {
    type: t.Enum(TransactionType),
    amount: t.Number(),
    currency: t.Optional(t.String({ minLength: 1 })),
    categoryId: t.Optional(t.String({ minLength: 1 })),
    fromAccountId: t.Optional(t.String({ minLength: 1 })),
    toAccountId: t.Optional(t.String({ minLength: 1 })),
    note: t.Optional(t.String()),
    tags: t.Optional(t.Array(t.String())),
  },
  { additionalProperties: false },
);

const RuleSchema = t.Object(
  {
    frequency: t.Enum(RecurringFrequency),
    interval: t.Number({ minimum: 1 }),
    startDate: t.Union([t.String(), t.Date()]),
    endDate: t.Optional(t.Union([t.String(), t.Date()])),
    template: TemplateSchema,
    isActive: t.Optional(t.Boolean()),
  },
  { additionalProperties: false },
);

const RunQuerySchema = t.Object(
  {
    period: t.Literal("monthly"),
    date: t.Optional(t.String({ minLength: 1 })),
  },
  { additionalProperties: false },
);

const MaterializeSchema = t.Object(
  {
    date: t.String({ minLength: 1 }),
  },
  { additionalProperties: false },
);

const SplitSchema = t.Object(
  {
    date: t.String({ minLength: 1 }),
    template: TemplateSchema,
  },
  { additionalProperties: false },
);

const ruleCreateCompiler = TypeCompiler.Compile(RuleSchema);
const ruleUpdateCompiler = TypeCompiler.Compile(t.Partial(RuleSchema));
const runQueryCompiler = TypeCompiler.Compile(RunQuerySchema);
const materializeCompiler = TypeCompiler.Compile(MaterializeSchema);
const splitCompiler = TypeCompiler.Compile(SplitSchema);

export function validateRecurringRulePayload(
  payload: RecurringRuleCreatePayload | RecurringRuleUpdatePayload,
  isUpdate: boolean,
): string | null {
  const compiler = isUpdate ? ruleUpdateCompiler : ruleCreateCompiler;
  if (compiler.Check(payload)) return null;
  for (const error of compiler.Errors(payload)) {
    if (error.path === "/frequency") return "Frecuencia invalida";
    if (error.path === "/interval") return "Intervalo invalido";
    if (error.path === "/startDate") return "Falta la fecha de inicio";
    if (error.path.startsWith("/template")) return "Plantilla invalida";
  }
  return "Payload invalido";
}

export function validateRecurringRunQuery(
  payload: RecurringRunQuery,
): string | null {
  if (runQueryCompiler.Check(payload)) return null;
  for (const error of runQueryCompiler.Errors(payload)) {
    if (error.path === "/period") return "Periodo invalido";
    if (error.path === "/date") return "Fecha invalida";
  }
  return "Payload invalido";
}

export function validateRecurringMaterializePayload(
  payload: RecurringMaterializePayload,
): string | null {
  if (materializeCompiler.Check(payload)) return null;
  for (const error of materializeCompiler.Errors(payload)) {
    if (error.path === "/date") return "Fecha invalida";
  }
  return "Payload invalido";
}

export function validateRecurringSplitPayload(
  payload: RecurringSplitPayload,
): string | null {
  if (splitCompiler.Check(payload)) return null;
  for (const error of splitCompiler.Errors(payload)) {
    if (error.path === "/date") return "Fecha invalida";
    if (error.path.startsWith("/template")) return "Plantilla invalida";
  }
  return "Payload invalido";
}
