import type { GoalPrimitives } from "../../models/goal"
import { Goal } from "../../models/goal"
import {
  GoalContribution,
  type GoalContributionPrimitives,
} from "../../models/goal_contribution"
import type { GoalContributionMongoRepository } from "../../repositories/goal_contribution_repository"
import type { GoalMongoRepository } from "../../repositories/goal_repository"
import type { GoalContributionsService } from "../../services/goal_contributions_service"
import type { GoalsService } from "../../services/goals_service"
import { buildGoalContributionsCriteria } from "../criteria/goal_contributions.criteria"
import { buildGoalsCriteria } from "../criteria/goals.criteria"
import type {
  GoalContributionCreatePayload,
  GoalContributionUpdatePayload,
} from "../validation/goal_contributions.validation"
import {
  validateGoalPayload,
  type GoalCreatePayload,
  type GoalUpdatePayload,
} from "../validation/goals.validation"

import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/goals")
export class GoalsController {
  private readonly repo: GoalMongoRepository
  private readonly contributionsRepo: GoalContributionMongoRepository
  private readonly service: GoalsService
  private readonly contributionsService: GoalContributionsService

  constructor() {
    const deps = Deps.getInstance()

    this.repo = deps.goalRepo
    this.service = deps.goalsService
    this.contributionsService = deps.goalContributionsService
    this.contributionsRepo = deps.goalContributionRepo
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const criteria = buildGoalsCriteria(query, req.userId ?? "")
    const result = await this.repo.list<GoalPrimitives>(criteria)

    return HttpResponse(res, {
      value: {
        ...result,
        results: result.results.map((item) =>
          Goal.fromPrimitives(item).toPrimitives()
        ),
      },
      status: 200,
    })
  }

  @Post("/")
  @Use([AuthMiddleware, validateGoalPayload(false)])
  async create(
    @Body() body: GoalCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.create(req.userId ?? "", body)
    return HttpResponse(res, result)
  }

  @Get("/:id")
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const goal = await this.repo.one({
      userId: req.userId ?? "",
      goalId: id,
    })

    if (!goal)
      return HttpResponse(res, { error: "Meta no encontrada", status: 404 })

    return HttpResponse(res, { value: goal.toPrimitives(), status: 200 })
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateGoalPayload(true)])
  async update(
    @Param("id") id: string,
    @Body() body: GoalUpdatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.update(req.userId ?? "", id, body)
    return HttpResponse(res, result)
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async remove(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.remove(req.userId ?? "", id)
    return HttpResponse(res, result)
  }

  @Get("/:id/projection")
  @Use([AuthMiddleware])
  async projection(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.projection(req.userId ?? "", id)
    return HttpResponse(res, result)
  }

  @Get("/:id/contributions")
  @Use([AuthMiddleware])
  async listContributions(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const criteria = buildGoalContributionsCriteria(query, req.userId ?? "")
    const result =
      await this.contributionsRepo.list<GoalContributionPrimitives>(criteria)
    return HttpResponse(res, {
      value: {
        ...result,
        results: result.results.map((item) =>
          GoalContribution.fromPrimitives(item).toPrimitives()
        ),
      },
      status: 200,
    })
  }

  @Post("/:id/contributions")
  @Use([AuthMiddleware])
  async createContribution(
    @Param("id") id: string,
    @Body() body: GoalContributionCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.contributionsService.create(req.userId ?? "", {
      ...body,
      goalId: id,
    })

    return HttpResponse(res, result)
  }

  @Put("/:id/contributions/:contributionId")
  @Use([AuthMiddleware, validateGoalPayload(true)])
  async updateContribution(
    @Param("id") id: string,
    @Param("contributionId") contributionId: string,
    @Body() body: GoalContributionUpdatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.contributionsService.update(
      req.userId ?? "",
      contributionId,
      body
    )

    return HttpResponse(res, result)
  }

  @Delete("/:id/contributions/:contributionId")
  @Use([AuthMiddleware])
  async removeContribution(
    @Param("id") id: string,
    @Param("contributionId") contributionId: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.contributionsService.remove(
      req.userId ?? "",
      contributionId
    )
    return HttpResponse(res, result)
  }
}
