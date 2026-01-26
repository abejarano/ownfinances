import { Controller, Get, Res, type ServerResponse } from "bun-platform-kit"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import { CountriesService } from "../../services/countries_service"

@Controller("/countries")
export class CountriesController {
  private service: CountriesService

  constructor() {
    this.service = Deps.resolve<CountriesService>("countriesService")
  }

  @Get("/")
  async index(@Res() res: ServerResponse) {
    try {
      const countries = await this.service.list()
      return HttpResponse(res, {
        value: {
          results: countries,
          count: countries.length,
        },
        status: 200,
      })
    } catch (e) {
      console.error("Error in CountriesController:", e)
      return HttpResponse(res, {
        value: { message: "Internal server error", error: String(e) },
        status: 500,
      })
    }
  }
}
