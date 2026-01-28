import { describe, expect, it, mock } from "bun:test"
import { BudgetsService } from "./budgets_service"
import type { BudgetCategoryPlanPayload } from "../http/validation/budgets.validation"

// Mock repo
const mockBudgetRepo = {
  upsert: mock(() => Promise.resolve()),
  one: mock(() => Promise.resolve(null)),
  delete: mock(() => Promise.resolve(true)),
}

describe("BudgetsService", () => {
  let service: BudgetsService
  service = new BudgetsService(mockBudgetRepo as any)

  describe("create", () => {
    it("should aggregate plannedTotal by currency correctly", async () => {
      // Reset mocks
      mockBudgetRepo.upsert = mock(() => Promise.resolve())
      mockBudgetRepo.one = mock(() => Promise.resolve(null))

      const categories: BudgetCategoryPlanPayload[] = [
        {
          categoryId: "cat1",
          entries: [
            { amount: 100, currency: "USD" },
            { amount: 50, currency: "BRL" },
            { amount: 200, currency: "USD" },
          ]
        }
      ]

      const result = await service.create("user1", {
        periodType: "monthly",
        startDate: "2026-01-01",
        endDate: "2026-01-31",
        categories,
      })

      expect(result.status).toBe(201)
      const budget = result.value!
      expect(budget.categories.length).toBe(1)
      const cat = budget.categories[0]
      
      // Check aggregation
      expect(cat.plannedTotal["USD"]).toBe(300) // 100 + 200
      expect(cat.plannedTotal["BRL"]).toBe(50)
      
      // Check entries normalization
      expect(cat.entries.length).toBe(3)
      expect(cat.entries[0].currency).toBe("USD")
      expect(cat.entries[1].currency).toBe("BRL")
    })
  })
})
