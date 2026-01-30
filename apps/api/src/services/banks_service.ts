import type { BankPrimitives } from "@desquadra/database"
import { BankMongoRepository } from "@desquadra/database"

export class BanksService {
  constructor(private readonly repo: BankMongoRepository) {}

  async list(country?: string): Promise<BankPrimitives[]> {
    const banks = await this.repo.banks(country)

    return banks.map((b: any) => (b.toPrimitives ? b.toPrimitives() : b))
  }
}
