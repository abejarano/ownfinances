import { type IJob, type TransactionGroupRequest } from "@desquadra/queue"

export class BankingCouncil implements IJob {
  async handle(args: TransactionGroupRequest): Promise<any> {
    console.info("Banking council", args)
  }
}
