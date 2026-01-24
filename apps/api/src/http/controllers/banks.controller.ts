import { Controller, Get, Query, Res, type ServerResponse } from "bun-platform-kit"
import { Deps } from "../../bootstrap/deps"
import { BanksService } from "../../services/banks_service"
import { HttpResponse } from "../../bootstrap/response"

@Controller("/banks")
export class BanksController {
    private service: BanksService

    constructor() {
        this.service = Deps.resolve<BanksService>("banksService")
    }

    @Get("/")
    async index(
        @Query() query: Record<string, string | undefined>,
        @Res() res: ServerResponse
    ) {
        try {
            const country = query.country
            // console.log("Fetching banks for country:", country);
            const banks = await this.service.list(country)
            return HttpResponse(res, {
                value: {
                    results: banks,
                    count: banks.length,
                },
                status: 200,
            })
        } catch (e) {
            console.error("Error in BanksController:", e)
            return HttpResponse(res, {
                value: { message: "Internal server error", error: String(e) },
                status: 500,
            })
        }
    }
}
