import {
  AccountMongoRepository,
  Transaction,
  TransactionMongoRepository,
  type TransactionPrimitives,
  TransactionStatus,
  TransactionType,
} from "@desquadra/database"
import type {
  IJob,
  TransactionAI,
  TransactionGroupRequest,
} from "@desquadra/queue"
import { Deps } from "../bootstrap/deps.ts"
import { formatDate } from "../helpers/dates.ts"

export class BankingCouncil implements IJob {
  private expense: TransactionAI[] | undefined
  private income: TransactionAI[] | undefined
  private transfer: TransactionAI[] | undefined

  constructor(
    private readonly transactionRepo: TransactionMongoRepository,
    private readonly accountRepo: AccountMongoRepository
  ) {
    this.transactionRepo =
      Deps.resolve<TransactionMongoRepository>("transactionRepo")

    this.accountRepo = Deps.resolve<AccountMongoRepository>("accountRepo")
  }

  async handle(args: TransactionGroupRequest): Promise<any> {
    console.info(
      `Banking council user: ${args.userId} month: ${args.month} year: ${args.year}`
    )
    const { year, month, expense, income, transfer } = args
    this.expense = expense
    this.income = income
    this.transfer = transfer

    const start = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0))
    const end = new Date(Date.UTC(year, month + 1, 1, 0, 0, 0, 0))

    const transactions = await this.transactionRepo.transtions({
      userId: args.userId,
      date: { $gte: start, $lt: end },
    })

    if (transactions.length === 0) {
      await this.registerAllTransaction(args)
      return
    }

    console.log(`transactions found ${transactions.length}`)

    for (const transaction of transactions) {
      this.spliceTransaction(transaction)
    }

    await this.registerAllTransaction(args, TransactionStatus.Pending)
  }

  private spliceTransaction(transactions: TransactionPrimitives) {
    switch (transactions.type) {
      case TransactionType.Expense:
        const indexExpense = this.expense!.findIndex(
          (e) =>
            e.amount === transactions.amount &&
            formatDate(e.originalDate) === transactions.date &&
            e.type === transactions.type
        )

        if (indexExpense !== -1) this.expense!.splice(indexExpense, 1)
        break

      case TransactionType.Income:
        const indexIncome = this.income!.findIndex(
          (e) =>
            e.amount === transactions.amount &&
            formatDate(e.originalDate) === transactions.date &&
            e.type === transactions.type
        )

        if (indexIncome !== -1) this.income!.splice(indexIncome, 1)
        break

      case TransactionType.Transfer:
        const indexTransfer = this.transfer!.findIndex(
          (e) =>
            e.amount === transactions.amount &&
            formatDate(e.originalDate) === transactions.date &&
            e.type === transactions.type
        )

        if (indexTransfer !== -1) this.transfer!.splice(indexTransfer, 1)
        break
    }
  }

  private async registerAllTransaction(
    args: TransactionGroupRequest,
    status: TransactionStatus = TransactionStatus.Cleared
  ) {
    const { income, expense, userId, currency, accountId } = args

    await Promise.all(
      income.map((i) => {
        return this.transactionRepo.upsert(
          Transaction.create({
            userId,
            type: TransactionType.Income,
            status,
            date: formatDate(i.originalDate),
            amount: Math.abs(i.amount),
            currency,
            categoryId: i.categoryId,
            toAccountId: accountId,
            note: i.originalDescription,
          })
        )
      })
    )

    await Promise.all(
      expense.map((i) => {
        return this.transactionRepo.upsert(
          Transaction.create({
            userId,
            type: TransactionType.Expense,
            status: TransactionStatus.Cleared,
            date: formatDate(i.originalDate),
            amount: Math.abs(i.amount),
            currency,
            categoryId: i.categoryId,
            toAccountId: accountId,
            note: i.originalDescription,
          })
        )
      })
    )
  }
}
