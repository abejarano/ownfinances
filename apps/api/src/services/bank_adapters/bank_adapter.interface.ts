import { TransactionType } from "../../models/transaction";

export type ParsedTransaction = {
  date: Date;
  amount: number;
  type: TransactionType;
  note?: string | null;
};

export interface BankAdapter {
  parseRow(row: string[], headers: string[]): ParsedTransaction | null;
  getExpectedHeaders(): string[];
}
