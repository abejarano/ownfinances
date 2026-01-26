import type { CountryPrimitives } from "../models/country"
import { CountryMongoRepository } from "../repositories/country_repository"

export class CountriesService {
  constructor(private readonly repo: CountryMongoRepository) {}

  async list(): Promise<CountryPrimitives[]> {
    const countries = await this.repo.countries()
    return countries.map((c: any) => (c.toPrimitives ? c.toPrimitives() : c))
  }
}
