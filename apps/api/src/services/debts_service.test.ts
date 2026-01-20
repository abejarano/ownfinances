import { describe, expect, it, mock } from "bun:test"
import { DebtsService } from "./debts_service"
import { DebtType } from "../models/debt"
import { DebtTransactionType } from "../models/debt_transaction"

// Mock repositories
const mockDebtRepo = {
  upsert: mock(() => Promise.resolve()),
  one: mock(() => Promise.resolve(null)),
  delete: mock(() => Promise.resolve(true)),
  list: mock(() => Promise.resolve({ results: [], total: 0 })),
}

const mockTransactionRepo = {
  upsert: mock(() => Promise.resolve()),
  list: mock(() => Promise.resolve({ results: [], total: 0 })),
  sumByDebt: mock(() => Promise.resolve([])),
}

describe("DebtsService", () => {
  let service: DebtsService

  service = new DebtsService(
    mockDebtRepo as any,
    mockTransactionRepo as any
  )

  describe("create", () => {
    it("should NOT create a transaction if initialBalance is 0", async () => {
      // Reset mocks
      mockTransactionRepo.upsert = mock(() => Promise.resolve())

      await service.create("user1", {
        name: "Test Card",
        type: DebtType.CreditCard,
        initialBalance: 0,
        linkedAccountId: "acc1",
      })

      // Expect debt upsert
      expect(mockDebtRepo.upsert).toHaveBeenCalled()
      
      // Expect NO transaction upsert
      expect(mockTransactionRepo.upsert).not.toHaveBeenCalled()
    })

    it("should create a charge transaction if initialBalance > 0", async () => {
      // Reset mocks
      mockTransactionRepo.upsert = mock(() => Promise.resolve())

      await service.create("user1", {
        name: "Old Debt",
        type: DebtType.CreditCard,
        initialBalance: 500,
        linkedAccountId: "acc1",
      })

      expect(mockDebtRepo.upsert).toHaveBeenCalled()
      expect(mockTransactionRepo.upsert).toHaveBeenCalledTimes(1)
      
      // We can inspect arguments if needed, but just ensuring it's called is good for MVP
      // If we want to be strict:
      const calls = (mockTransactionRepo.upsert as any).mock.calls
      const tx = calls[0][0]
      expect(tx.toPrimitives().amount).toBe(500)
      expect(tx.toPrimitives().type).toBe(DebtTransactionType.Charge)
      expect(tx.toPrimitives().note).toBe("Saldo inicial")
    })
  })

  describe("summary", () => {
    it("should calculate amountDue=0 and creditBalance>0 when payments exceed chargs", async () => {
      const debtId = "debt1"
      const userId = "user1"

      // Mock debt existing
      mockDebtRepo.one = mock(() => Promise.resolve({
        toPrimitives: () => ({ dueDay: 10, name: "Test" }) // partial mock
      } as any))

      // Mock transactions sum
      // Charges: 100, Payments: 150
      mockTransactionRepo.sumByDebt = mock((uid, filters) => {
        // sumByDebt is called twice: once for totals, once for this month payments
        // We can distinguish by args or just return generic structure if simple
        
        // If filters has 'start' it's likely the monthly payments check
        if (filters.start) {
             return Promise.resolve([{ type: DebtTransactionType.Payment, total: 50 }]) 
        }

        // Overall totals
        return Promise.resolve([
            { type: DebtTransactionType.Charge, total: 100 },
            { type: DebtTransactionType.Payment, total: 150 }
        ])
      })

      const result = await service.summary(userId, debtId)
      
      expect(result.status).toBe(200)
      const data = result.value!
      
      // Balance = 100 - 150 = -50
      // AmountDue = max(0, -50) = 0
      // CreditBalance = abs(-50) = 50
      expect(data.amountDue).toBe(0)
      expect(data.creditBalance).toBe(50)
    })
  })
})
