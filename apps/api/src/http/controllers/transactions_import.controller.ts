import type { TransactionsImportService } from "../../services/transactions_import_service";
import { badRequest } from "../errors";

export class TransactionsImportController {
  constructor(
    private readonly importService: TransactionsImportService
  ) {}

  async preview({
    body,
    set,
    userId,
  }: {
    body: any;
    set: { status: number };
    userId?: string;
  }) {
    try {
      // Elysia parsea multipart automáticamente
      // El body puede tener accountId como campo y file como File
      const accountId = body.accountId;
      const file = body.file;

      if (!file) {
        return badRequest(set, "Falta o arquivo CSV");
      }

      // En Bun, File tiene método text()
      const fileContent = typeof file === "string" ? file : await file.text();
      const result = await this.importService.process(
        userId ?? "",
        accountId,
        fileContent,
        "preview"
      );
      return result;
    } catch (error: any) {
      return badRequest(set, error.message || "Erro ao processar preview");
    }
  }

  async import({
    body,
    set,
    userId,
  }: {
    body: any;
    set: { status: number };
    userId?: string;
  }) {
    try {
      // Elysia parsea multipart automáticamente
      const accountId = body.accountId;
      const file = body.file;

      if (!file) {
        return badRequest(set, "Falta o arquivo CSV");
      }

      // En Bun, File tiene método text()
      const fileContent = typeof file === "string" ? file : await file.text();
      const result = await this.importService.process(
        userId ?? "",
        accountId,
        fileContent,
        "import"
      );
      return result;
    } catch (error: any) {
      return badRequest(set, error.message || "Erro ao iniciar import");
    }
  }
}
