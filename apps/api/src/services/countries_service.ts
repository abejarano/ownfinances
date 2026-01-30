import type { CountryPrimitives } from "@desquadra/database"
import { CountryMongoRepository } from "@desquadra/database"

export class CountriesService {
  constructor(private readonly repo: CountryMongoRepository) {}

  async list(): Promise<CountryPrimitives[]> {
    const countries = await this.repo.countries()
    return countries.map((c: any) => (c.toPrimitives ? c.toPrimitives() : c))
  }
}
