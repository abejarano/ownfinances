import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"
import type { CategoryKind } from "../../models/category"

export type CategoryCreatePayload = {
  name: string
  kind: CategoryKind
  parentId?: string | null
  color?: string | null
  icon?: string | null
  isActive?: boolean
}

export type CategoryUpdatePayload = Partial<CategoryCreatePayload>

const CategoryKindSchema = v.picklist(["income", "expense"])

const CategoryBaseSchema = v.strictObject({
  name: v.pipe(v.string(), v.minLength(1)),
  kind: CategoryKindSchema,
  parentId: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  color: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  icon: v.optional(v.nullable(v.pipe(v.string(), v.minLength(1)))),
  isActive: v.optional(v.boolean()),
})

const CategoryCreateSchema = CategoryBaseSchema
const CategoryUpdateSchema = v.partial(CategoryBaseSchema)

export function validateCategoryPayload(isUpdate: boolean) {
  return async (
    req: ServerRequest,
    res: ServerResponse,
    next: NextFunction
  ): Promise<void> => {
    const payload = req.body
    const schema = isUpdate ? CategoryUpdateSchema : CategoryCreateSchema
    const result = v.safeParse(schema, payload)

    if (result.success) return next()

    if (!result.issues) return res.status(422).send("Payload invalido")
    const flattened = v.flatten(result.issues)

    if (flattened.nested?.name)
      return res.status(422).send("Falta o nome da categoria")

    if (flattened.nested?.kind)
      return res.status(422).send("Tipo de categoria invalido")

    return res.status(422).send("Payload invalido")
  }
}
