export type TransactionAI = {
  originalDate: string;
  originalDescription: string;
  amount: number;
  categoryId: string;
  categoryName: string;
  type: "income" | "expense" | "transfer";
  reasoning: string;
};
export type TransactionGroupRequest = {
  userId: string;
  accountId: string;
  year: number;
  month: number;
  currency: string;
  expense: TransactionAI[];
  income: TransactionAI[];
  transfer: TransactionAI[];
};
