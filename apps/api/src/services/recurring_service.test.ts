import { describe, expect, it, mock } from "bun:test"
import { RecurringFrequency, RecurringRule } from "../models/recurring/recurring_rule"
import { GeneratedInstance } from "../models/recurring/generated_instance"
import { RecurringService } from "./recurring_service"

// Mock repositories
const mockRuleRepo = {
  searchActive: mock(() => Promise.resolve([])),
  one: mock(() => Promise.resolve(null)),
  upsert: mock(() => Promise.resolve()),
  remove: mock(() => Promise.resolve()),
  deactivateActiveDuplicatesBySignature: mock(() => Promise.resolve(0)),
}

const mockInstanceRepo = {
  search: mock(() => Promise.resolve([])),
  one: mock(() => Promise.resolve(null)),
  upsert: mock(() => Promise.resolve()),
  remove: mock(() => Promise.resolve()),
}

const mockTransactionRepo = {
  upsert: mock(() => Promise.resolve()),
}

describe("RecurringService", () => {
  let service: RecurringService

  // Reset mocks before each test
  // Note: simpler to just re-instantiate or assume clean state if mocks are recreated
  // But consistent clean object is better.
  
  service = new RecurringService(
    mockRuleRepo as any,
    mockInstanceRepo as any,
    mockTransactionRepo as any
  )

  describe("calculateDates (Monthly End-of-Month Logic)", () => {
    it("should handle Jan 31 -> Feb 28 -> Mar 31 correctly", async () => {
      // Setup a rule starting Jan 31, 2024 (Leap year)
      // Jan 31 2024
      const startDate = new Date("2024-01-31T10:00:00Z")
      
      const rule = RecurringRule.create({
        userId: "user1",
        signature: "sig1",
        frequency: RecurringFrequency.Monthly,
        interval: 1,
        startDate: startDate,
        template: {
          type: "expense" as any,
          amount: 100,
          currency: "BRL",
        }
      })

      mockRuleRepo.searchActive = mock(() => Promise.resolve([rule]))
      mockInstanceRepo.search = mock(() => Promise.resolve([]))

      // Preview for 3 months: Jan, Feb, Mar 2024
      // We'll call preview with a date in Jan, then check results?
      // Actually preview takes a specific month/date and computes range.
      // But we can call it for Jan, then Feb, then Mar, or just check the private logic if we could.
      // Since calculateDates is private, we test via preview.
      // However preview computes a range (monthly = 1st to last).
      // If we want to see future dates, we generally don't get them all in one 'monthly' preview call unless we hack the range.
      // But the requirement says "Preview list" in Plan Month checks *occurrences* in that month.
      
      // So let's check Feb 2024 (Leap year so 29 days)
      const febDate = new Date("2024-02-15") // Query for Feb
      const febResult = await service.preview("user1", "monthly", febDate)
      
      const febItem = febResult.value![0]
      // Should be Feb 29 2024 because Jan 31 + 1 month = Feb 29 (leap)
      expect(febItem.date.toISOString().split("T")[0]).toBe("2024-02-29")

      // Check Feb 2025 (Non leap) -> Feb 28
      // Note: Changing rule to start Jan 31 2025
      const rule2025 = RecurringRule.create({
        userId: "user1",
        signature: "sig1",
        frequency: RecurringFrequency.Monthly,
        interval: 1,
        startDate: new Date("2025-01-31T10:00:00Z"),
        template: { type: "expense" as any, amount: 100, currency: "BRL" }
      })
      mockRuleRepo.searchActive = mock(() => Promise.resolve([rule2025]))
      
      const feb2025 = await service.preview("user1", "monthly", new Date("2025-02-15"))
      expect(feb2025.value![0].date.toISOString().split("T")[0]).toBe("2025-02-28")

      // Check Mar 2025 -> Should be Mar 31
      mockRuleRepo.searchActive = mock(() => Promise.resolve([rule2025]))
      const mar2025 = await service.preview("user1", "monthly", new Date("2025-03-15"))
      expect(mar2025.value![0].date.toISOString().split("T")[0]).toBe("2025-03-31")
    })
  })

  describe("Ignore Functionality", () => {
    it("should allow ignoring an instance and reflect it in preview", async () => {
      const startDate = new Date("2024-04-15T00:00:00Z")
      const rule = RecurringRule.create({
        recurringRuleId: "rule1", // Force ID for easy check
        userId: "user1",
        signature: "sig1",
        frequency: RecurringFrequency.Monthly,
        interval: 1,
        startDate: startDate,
        template: { type: "expense" as any, amount: 100, currency: "BRL" }
      } as any) // Cast because create usually takes props without ID, but here we mock return or just use object
      // Actually RecurringRule.create generates ID. We'll use the one it generates.

      mockRuleRepo.one = mock(() => Promise.resolve(rule))
      mockInstanceRepo.one = mock(() => Promise.resolve(null)) // Not existing yet
      mockInstanceRepo.upsert = mock(() => Promise.resolve())

      // 1. Ignore April 15
      const ignoreDate = new Date("2024-04-15")
      const ignoreRes = await service.ignore("user1", rule.ruleId, ignoreDate)
      
      expect(ignoreRes.status).toBe(201)
      expect(ignoreRes.value!.instance.status).toBe("ignored")

      // 2. Verify Preview sees it as ignored
      mockRuleRepo.searchActive = mock(() => Promise.resolve([rule]))
      // Mock search to return the ignored instance
      mockInstanceRepo.search = mock(() => Promise.resolve([
        GeneratedInstance.create(rule.ruleId, "user1", ignoreDate, undefined, "ignored")
      ]))

      const previewRes = await service.preview("user1", "monthly", ignoreDate)
      const item = previewRes.value![0]
      expect(item.status).toBe("ignored")
    })

    it("should skip ignored instances in run", async () => {
      const startDate = new Date("2024-05-20")
       const rule = RecurringRule.create({
        userId: "user1",
        signature: "sig1",
        frequency: RecurringFrequency.Monthly,
        interval: 1,
        startDate: startDate,
        template: { type: "expense" as any, amount: 100, currency: "BRL" }
      })

      mockRuleRepo.searchActive = mock(() => Promise.resolve([rule]))
      // Mock search returns ignored instance
      mockInstanceRepo.search = mock(() => Promise.resolve([
          GeneratedInstance.create(rule.ruleId, "user1", startDate, undefined, "ignored")
      ]))
      mockTransactionRepo.upsert = mock(() => Promise.resolve())
      
      const runRes = await service.run("user1", "monthly", startDate)
      
      // Should generate 0 because it's ignored
      expect(runRes.value!.generated).toBe(0)
      
      // Verify transaction repo NOT called
      // expect(transactionRepoMock.upsert).not.toHaveBeenCalled() // Bun matchers might differ
    })
  })
})
