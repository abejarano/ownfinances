import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";
import type { CategoryKind } from "../../models/category";

export type CategoryCreatePayload = {
  name: string;
  kind: CategoryKind;
  parentId?: string | null;
  color?: string | null;
  icon?: string | null;
  isActive?: boolean;
};

export type CategoryUpdatePayload = Partial<CategoryCreatePayload>;

const CategoryKindSchema = t.Union([t.Literal("income"), t.Literal("expense")]);

const CategoryBaseSchema = t.Object(
  {
    name: t.String({ minLength: 1 }),
    kind: CategoryKindSchema,
    parentId: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    color: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    icon: t.Optional(t.Union([t.String({ minLength: 1 }), t.Null()])),
    isActive: t.Optional(t.Boolean()),
  },
  { additionalProperties: false }
);

const CategoryCreateSchema = CategoryBaseSchema;
const CategoryUpdateSchema = t.Partial(CategoryBaseSchema);

const categoryCreateCompiler = TypeCompiler.Compile(CategoryCreateSchema);
const categoryUpdateCompiler = TypeCompiler.Compile(CategoryUpdateSchema);

export function validateCategoryPayload(
  payload: CategoryCreatePayload | CategoryUpdatePayload,
  isUpdate: boolean
): string | null {
  const compiler = isUpdate ? categoryUpdateCompiler : categoryCreateCompiler;
  if (compiler.Check(payload)) {
    return null;
  }

  for (const error of compiler.Errors(payload)) {
    if (error.path === "/name") return "Falta el nombre de la categoria";
    if (error.path === "/kind") return "Tipo de categoria invalido";
  }

  return "Payload invalido";
}
