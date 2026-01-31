import { type IJob, QueueDispatcher, QueueName } from "@desquadra/queue";
import { CategoryMongoRepository } from "@desquadra/database";
import ClassifyTransactionService, {
  type TransactionResponse,
} from "./service/classify.transaction.service.ts";

type TransactionGroup = {
  userId: string;
  accountId: string;
  expense: TransactionResponse[];
  income: TransactionResponse[];
  transfer: TransactionResponse[];
};

export type CategorizerTransactionsJob = {
  userId: string;
  userName: string;
  accountId: string;
  countryCode: string;
  file: any;
};

export class CategorizeTransactions implements IJob {
  constructor(private readonly categoryRepo: CategoryMongoRepository) {}

  async handle(args: CategorizerTransactionsJob): Promise<any | void> {
    const { userId, accountId, countryCode, file, userName } = args;

    const categories = await this.categoryRepo.search(userId);

    const response = await ClassifyTransactionService({
      userName: userName,
      userCountry: countryCode,
      csv: file,
      categories: JSON.stringify(categories),
      test: true,
    });

    const items = response.reduce<Record<string, TransactionResponse[]>>(
      (acc, item) => {
        const key = item.type ?? "unknown";
        (acc[key] ??= []).push(item);
        return acc;
      },
      {},
    );

    const transactionGroup: TransactionGroup = {
      ...items,
      userId,
      accountId,
    } as TransactionGroup;

    console.log("user: ", userName);
    console.log("expense: ", transactionGroup.expense.length);
    console.log("income: ", transactionGroup.income.length);
    console.log("transfer: ", transactionGroup.transfer.length);

    QueueDispatcher.getInstance().dispatch(
      QueueName.BankingCouncil,
      transactionGroup,
    );
  }
}
