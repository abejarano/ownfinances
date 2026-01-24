import { Criteria, Filters, Operator, Order, type FilterInputValue } from "@abejarano/ts-mongodb-criteria"
import { BankMongoRepository } from "../repositories/bank_repository"
import type { BankPrimitives } from "../models/bank"


export class BanksService {
  constructor(private readonly repo: BankMongoRepository) {}

  async list(country?: string): Promise<BankPrimitives[]> {
    const banks = await this.repo.banks(country)

    return banks.map((b: any) => b.toPrimitives ? b.toPrimitives() : b)

  }
}
