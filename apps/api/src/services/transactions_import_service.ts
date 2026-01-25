import { createHash } from "crypto"
import type { Result } from "../bootstrap/response"
import { AccountType } from "../models/account"
import { BankType } from "../models/bank_type"
import { ImportJob, ImportJobStatus } from "../models/import_job"
import { Transaction, TransactionStatus } from "../models/transaction"
import type { AccountMongoRepository } from "../repositories/account_repository"
import type { ImportJobMongoRepository } from "../repositories/import_job_repository"
import type { TransactionMongoRepository } from "../repositories/transaction_repository"
import { getBankAdapter } from "./bank_adapters"
import type { BankAdapter } from "./bank_adapters/bank_adapter.interface"

export type ImportPreviewRow = {
  row: number
  date: string
  amount: number
  type: string
  note: string | null
}

export type ImportPreview = {
  rows: ImportPreviewRow[]
  totalRows: number
}

export class TransactionsImportService {
  constructor(
    private readonly transactionRepo: TransactionMongoRepository,
    private readonly importJobRepo: ImportJobMongoRepository,
    private readonly accountRepo: AccountMongoRepository
  ) {}

  async process(
    userId: string,
    accountId: string,
    csvContent: string,
    mode: "preview" | "import"
  ): Promise<Result<ImportPreview | { jobId: string }>> {
    const account = await this.accountRepo.one({ userId, accountId })
    if (!account) {
      return { error: "Conta não encontrada", status: 404 }
    }

    const bankType = account.getBankType()
    if (account.getType() !== AccountType.Bank || !bankType) {
      return {
        error: "Conta deve ser do tipo banco com bankType definido",
        status: 400,
      }
    }

    const adapter = getBankAdapter(bankType)
    const rows = this.parseCSV(csvContent)
    const totalRows = Math.max(rows.length - 1, 0) // Excluir header

    const preview = this.buildPreview(adapter, rows)
    if (mode === "preview") {
      return { value: preview, status: 200 }
    }

    const importJob = ImportJob.create({
      userId,
      accountId,
      bankType,
      totalRows,
    })

    await this.importJobRepo.upsert(importJob)

    // Processar em background (não bloquear)
    this.processImportInBackground(
      userId,
      accountId,
      bankType,
      csvContent,
      importJob.getImportJobId()
    ).catch((error) => {
      console.error("Erro ao processar import:", error)
    })

    return { value: { jobId: importJob.getImportJobId() }, status: 200 }
  }

  private buildPreview(adapter: BankAdapter, rows: string[][]): ImportPreview {
    if (rows.length === 0) {
      return { rows: [], totalRows: 0 }
    }

    const headers = rows[0]
    const previewRows: ImportPreviewRow[] = []
    const maxPreview = Math.min(10, rows.length - 1)

    for (let i = 1; i <= maxPreview; i++) {
      const parsed = adapter.parseRow(rows[i]!, headers!)
      if (parsed) {
        previewRows.push({
          row: i,
          date: parsed.date.toISOString().split("T")[0]!,
          amount: parsed.amount,
          type: parsed.type,
          note: parsed.note || null,
        })
      }
    }

    return {
      rows: previewRows,
      totalRows: rows.length - 1,
    }
  }

  private async processImportInBackground(
    userId: string,
    accountId: string,
    bankType: BankType,
    csvContent: string,
    jobId: string
  ): Promise<void> {
    const job = await this.importJobRepo.one({ userId, importJobId: jobId })
    if (!job) return

    const jobPrimitives = job.toPrimitives()
    const updatedJob = ImportJob.fromPrimitives({
      ...jobPrimitives,
      status: ImportJobStatus.Processing,
    })
    await this.importJobRepo.upsert(updatedJob)

    try {
      const adapter = getBankAdapter(bankType)
      const rows = this.parseCSV(csvContent)
      if (!rows[0]) {
        throw new Error("CSV vazio")
      }
      const headers = rows[0]!

      let imported = 0
      let duplicates = 0
      let errors = 0
      const errorDetails: Array<{ row: number; error: string }> = []

      const account = await this.accountRepo.one({ userId, accountId })
      if (!account) {
        throw new Error("Conta não encontrada")
      }
      const accountPrimitives = account.toPrimitives()

      const transactionsToInsert: Transaction[] = []

      for (let i = 1; i < rows.length; i++) {
        try {
          const parsed = adapter.parseRow(rows[i]!, headers)
          if (!parsed) {
            errors++
            errorDetails.push({
              row: i + 1,
              error: "Não foi possível parsear a linha",
            })
            continue
          }

          const fingerprint = this.generateFingerprint(
            userId,
            parsed.date,
            parsed.amount,
            accountId,
            parsed.type
          )

          // Verificar duplicado
          const existing = await this.transactionRepo.one({
            userId,
            importFingerprint: fingerprint,
            deletedAt: null,
          })
          if (existing) {
            duplicates++
            continue
          }

          const transaction = Transaction.create({
            userId,
            type: parsed.type,
            date: parsed.date,
            amount: parsed.amount,
            currency: accountPrimitives.currency,
            categoryId: null,
            fromAccountId: parsed.type === "expense" ? accountId : null,
            toAccountId: parsed.type === "income" ? accountId : null,
            note: parsed.note,
            tags: null,
            status: TransactionStatus.Cleared,
            clearedAt: parsed.date,
          })

          const transactionPrimitives = transaction.toPrimitives()
          const transactionWithFingerprint = Transaction.fromPrimitives({
            ...transactionPrimitives,
            importFingerprint: fingerprint,
          })

          transactionsToInsert.push(transactionWithFingerprint)
          imported++

          // Batch insert a cada 100 transações
          if (transactionsToInsert.length >= 100) {
            await this.batchInsert(transactionsToInsert)
            transactionsToInsert.length = 0
          }
        } catch (error: any) {
          errors++
          errorDetails.push({
            row: i + 1,
            error: error.message || "Erro desconhecido",
          })
        }
      }

      // Inserir transações restantes
      if (transactionsToInsert.length > 0) {
        await this.batchInsert(transactionsToInsert)
      }

      const finalJob = await this.importJobRepo.one({
        userId,
        importJobId: jobId,
      })
      if (finalJob) {
        const finalPrimitives = finalJob.toPrimitives()
        const completedJob = ImportJob.fromPrimitives({
          ...finalPrimitives,
          status: ImportJobStatus.Completed,
          imported,
          duplicates,
          errors,
          errorDetails,
          completedAt: new Date(),
        })
        await this.importJobRepo.upsert(completedJob)

        // Notificar via WebSocket
        // notifyImportCompleted(userId, jobId, "completed", {
        //   imported,
        //   duplicates,
        //   errors,
        // });
      }
    } catch (error: any) {
      const failedJob = await this.importJobRepo.one({
        userId,
        importJobId: jobId,
      })
      if (failedJob) {
        const failedPrimitives = failedJob.toPrimitives()
        const errorJob = ImportJob.fromPrimitives({
          ...failedPrimitives,
          status: ImportJobStatus.Failed,
          errors: failedPrimitives.totalRows,
          errorDetails: [
            {
              row: 0,
              error: error.message || "Erro ao processar import",
            },
          ],
          completedAt: new Date(),
        })
        await this.importJobRepo.upsert(errorJob)

        // Notificar via WebSocket
        // notifyImportCompleted(userId, jobId, "failed", {
        //   imported: 0,
        //   duplicates: 0,
        //   errors: failedPrimitives.totalRows,
        // });
      }
    }
  }

  private async batchInsert(transactions: Transaction[]): Promise<void> {
    for (const transaction of transactions) {
      await this.transactionRepo.upsert(transaction)
    }
  }

  private generateFingerprint(
    userId: string,
    date: Date,
    amount: number,
    accountId: string,
    type: string
  ): string {
    const dateStr = date.toISOString().split("T")[0]
    const data = `${userId}|${dateStr}|${amount}|${accountId}|${type}`
    return createHash("sha256").update(data).digest("hex")
  }

  private parseCSV(content: string): string[][] {
    const lines = content.split(/\r?\n/).filter((line) => line.trim())
    return lines.map((line) => {
      const result: string[] = []
      let current = ""
      let inQuotes = false

      for (let i = 0; i < line.length; i++) {
        const char = line[i]
        if (char === '"') {
          inQuotes = !inQuotes
        } else if (char === "," && !inQuotes) {
          result.push(current.trim())
          current = ""
        } else {
          current += char
        }
      }
      result.push(current.trim())
      return result
    })
  }
}
