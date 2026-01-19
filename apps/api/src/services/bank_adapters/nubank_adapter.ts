import { TransactionType } from "../../models/transaction"
import { BankAdapter, ParsedTransaction } from "./bank_adapter.interface"

export class NubankAdapter implements BankAdapter {
  getExpectedHeaders(): string[] {
    return ["data", "descricao", "valor"]
  }

  parseRow(row: string[], headers: string[]): ParsedTransaction | null {
    try {
      const dataIndex = headers.findIndex(
        (h) => h.toLowerCase() === "data" || h.toLowerCase() === "date"
      )
      const descricaoIndex = headers.findIndex(
        (h) =>
          h.toLowerCase() === "descricao" ||
          h.toLowerCase() === "descrição" ||
          h.toLowerCase() === "description"
      )
      const valorIndex = headers.findIndex(
        (h) => h.toLowerCase() === "valor" || h.toLowerCase() === "amount"
      )

      if (dataIndex === -1 || valorIndex === -1) {
        return null
      }

      const dateStr = row[dataIndex]?.trim()
      const valorStr = row[valorIndex]?.trim()
      const descricao = row[descricaoIndex]?.trim() || null

      if (!dateStr || !valorStr) {
        return null
      }

      // Formato Nubank: DD/MM/YYYY
      const date = this.parseDate(dateStr)
      if (!date) {
        return null
      }

      // Formato Nubank: -1234.56 (negativo para saída)
      const amount = this.parseAmount(valorStr)
      if (amount === null) {
        return null
      }

      const type = amount < 0 ? TransactionType.Expense : TransactionType.Income

      return {
        date,
        amount: Math.abs(amount),
        type,
        note: descricao,
      }
    } catch {
      return null
    }
  }

  private parseDate(dateStr: string): Date | null {
    // Formato Nubank: DD/MM/YYYY
    const parts = dateStr.split("/")
    if (parts.length === 3) {
      const day = parseInt(parts[0], 10)
      const month = parseInt(parts[1], 10) - 1
      const year = parseInt(parts[2], 10)
      const date = new Date(year, month, day)
      if (!isNaN(date.getTime())) {
        return date
      }
    }
    return null
  }

  private parseAmount(amountStr: string): number | null {
    // Se tiver vírgula e ponto, assume formato 1.234,56
    if (amountStr.includes(",") && amountStr.includes(".")) {
      const cleaned = amountStr.replace(/\./g, "").replace(",", ".")
      const amount = parseFloat(cleaned)
      return isNaN(amount) ? null : amount
    }

    // Se tiver apenas vírgula, assume 1234,56
    if (amountStr.includes(",")) {
      const cleaned = amountStr.replace(",", ".")
      const amount = parseFloat(cleaned)
      return isNaN(amount) ? null : amount
    }

    // Se tiver apenas ponto, assume 1234.56
    const amount = parseFloat(amountStr)
    return isNaN(amount) ? null : amount
  }
}
