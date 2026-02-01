import {
  type CategorizerTransactionRequest,
  type IJob,
  QueueDispatcher,
  QueueName,
  type TransactionAI,
  type TransactionGroupRequest,
} from "@desquadra/queue";
import { CategoryMongoRepository } from "@desquadra/database";
import ClassifyTransactionService from "./service/classify.transaction.service.ts";

export class CategorizeTransactions implements IJob {
  constructor(private readonly categoryRepo: CategoryMongoRepository) {}

  async handle(args: CategorizerTransactionRequest): Promise<any | void> {
    const {
      userId,
      accountId,
      countryCode,
      file,
      userName,
      month,
      year,
      currency,
    } = args;

    const categories = await this.categoryRepo.search(userId);

    const response = await ClassifyTransactionService({
      userName: userName,
      userCountry: countryCode,
      csv: file,
      categories: JSON.stringify(categories),
    });

    const items = response.reduce<Record<string, TransactionAI[]>>(
      (acc, item) => {
        const key = item.type ?? "unknown";
        (acc[key] ??= []).push(item);
        return acc;
      },
      {},
    );

    const transactionGroup: TransactionGroupRequest = {
      ...items,
      userId,
      accountId,
      year,
      month,
      currency,
    } as TransactionGroupRequest;

    console.log("user: ", userName);
    console.log("expense: ", transactionGroup.expense.length);
    console.log("income: ", transactionGroup.income.length);
    console.log("transfer: ", transactionGroup.transfer.length);

    QueueDispatcher.getInstance().dispatch<TransactionGroupRequest>(
      QueueName.BankingCouncil,
      transactionGroup,
    );
  }
}
