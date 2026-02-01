import {
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

export class BankingCouncil implements IJob {
  private expense: TransactionAI[] | undefined

  constructor(private readonly transactionRepo: TransactionMongoRepository) {
    this.transactionRepo =
      Deps.resolve<TransactionMongoRepository>("transactionRepo")
  }

  async handle(args: TransactionGroupRequest): Promise<any> {
    console.info(
      `Banking council user: ${args.userId} month: ${args.month} year: ${args.year}`
    )
    const { year, month } = args

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

    this.expense = args.expense

    console.log(`fonds transaction ${transactions.length}`)

    for (const transaction of transactions) {
    }
  }

  private async registerAllTransaction(args: TransactionGroupRequest) {
    const { income, expense, userId, currency, accountId } = args

    await Promise.all(
      income.map((i) => {
        return this.transactionRepo.upsert(
          Transaction.create({
            userId,
            type: TransactionType.Income,
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

  private async findExpense(transactions: TransactionPrimitives) {
    const formatDate = (originalDate: string) => {
      const parts = originalDate.split("/")

      const dd = Number(parts[0])
      const mm = Number(parts[1])
      const yyyy = Number(parts[2])

      return new Date(Date.UTC(yyyy, mm - 1, dd, 0, 0, 0, 0))
    }

    const transaction = this.expense!.find(
      (e) =>
        e.amount === transactions.amount &&
        formatDate(e.originalDate) === transactions.date
    )
  }
}

const formatDate = (originalDate: string) => {
  const parts = originalDate.split("/")

  const dd = Number(parts[0])
  const mm = Number(parts[1])
  const yyyy = Number(parts[2])

  return new Date(Date.UTC(yyyy, mm - 1, dd, 0, 0, 0, 0))
}
