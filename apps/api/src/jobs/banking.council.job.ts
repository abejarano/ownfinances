import type { IJob } from "@desquadra/queue"

export class BankingCouncil implements IJob {
  async handle(args: any): Promise<any> {
    console.info("Banking council", args)
  }
}
