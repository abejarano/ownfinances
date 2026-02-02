import type { BudgetPeriodType } from "@desquadra/database"

export type DateInput = Date | string

export function resolveUtcYearMonth(input: DateInput) {
  if (typeof input === "string") {
    const match = /^(\d{4})-(\d{2})/.exec(input)
    if (match) {
      return { year: Number(match[1]), month: Number(match[2]) - 1 }
    }
    const parsed = new Date(input)
    return { year: parsed.getUTCFullYear(), month: parsed.getUTCMonth() }
  }

  return { year: input.getUTCFullYear(), month: input.getUTCMonth() }
}

export function getRangeAnchorDate(range: { start: Date; end: Date }) {
  const midpoint =
    range.start.getTime() +
    Math.floor((range.end.getTime() - range.start.getTime()) / 2)
  return new Date(midpoint)
}

export function computePeriodRange(period: BudgetPeriodType, date: DateInput) {
  const { year, month } = resolveUtcYearMonth(date)
  let start: Date
  let end: Date

  if (period === "monthly") {
    start = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0))
    end = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999))
  } else if (period === "quarterly") {
    const quarterStart = Math.floor(month / 3) * 3
    start = new Date(Date.UTC(year, quarterStart, 1, 0, 0, 0, 0))
    end = new Date(Date.UTC(year, quarterStart + 3, 0, 23, 59, 59, 999))
  } else if (period === "semiannual") {
    const halfStart = month < 6 ? 0 : 6
    start = new Date(Date.UTC(year, halfStart, 1, 0, 0, 0, 0))
    end = new Date(Date.UTC(year, halfStart + 6, 0, 23, 59, 59, 999))
  } else {
    start = new Date(Date.UTC(year, 0, 1, 0, 0, 0, 0))
    end = new Date(Date.UTC(year, 12, 0, 23, 59, 59, 999))
  }

  return { start, end }
}

export const formatDate = (originalDate: string) => {
  const parts = originalDate.split("/")

  const dd = Number(parts[0])
  const mm = Number(parts[1])
  const yyyy = Number(parts[2])

  return new Date(Date.UTC(yyyy, mm - 1, dd, 0, 0, 0, 0))
}
