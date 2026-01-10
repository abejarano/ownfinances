import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";

export type ImportPreviewPayload = {
  accountId: string;
};

export type ImportPayload = {
  accountId: string;
};

const ImportPreviewPayloadSchema = t.Object({
  accountId: t.String({ minLength: 1 }),
});

const ImportPayloadSchema = t.Object({
  accountId: t.String({ minLength: 1 }),
});

const importPreviewPayloadCompiler = TypeCompiler.Compile(ImportPreviewPayloadSchema);
const importPayloadCompiler = TypeCompiler.Compile(ImportPayloadSchema);

export function validateImportPreviewPayload(
  payload: ImportPreviewPayload
): string | null {
  if (!importPreviewPayloadCompiler.Check(payload)) {
    if (!payload.accountId) {
      return "Falta o accountId";
    }
    return "Payload invalido";
  }
  return null;
}

export function validateImportPayload(
  payload: ImportPayload
): string | null {
  if (!importPayloadCompiler.Check(payload)) {
    if (!payload.accountId) {
      return "Falta o accountId";
    }
    return "Payload invalido";
  }
  return null;
}
