import {
  Criteria,
  Filters,
  Operator,
  Order,
  type FilterInputValue,
} from "@abejarano/ts-mongodb-criteria"

export function buildBudgetsCriteria(
  query: Record<string, string | undefined>,
  userId: string
) {
  const filters: Array<Map<string, FilterInputValue>> = [
    new Map<string, FilterInputValue>([
      ["field", "userId"],
      ["operator", Operator.EQUAL],
      ["value", userId],
    ]),
  ]

  if (query.periodType) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "periodType"],
        ["operator", Operator.EQUAL],
        ["value", query.periodType],
      ])
    )
  }

  if (query.dateFrom && query.dateTo) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "startDate"],
        ["operator", Operator.GTE],
        ["value", new Date(query.dateFrom)],
      ])
    )
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "endDate"],
        ["operator", Operator.LTE],
        ["value", new Date(query.dateTo)],
      ])
    )
  }



  const limit = query.limit ? Number(query.limit) : 20
  const page = query.page ? Number(query.page) : 1
  const order = buildOrder(query.sort, Order.desc("startDate"))

  return new Criteria(Filters.fromValues(filters), order, limit, page)
}

function buildOrder(sort?: string, fallback?: Order): Order {
  if (!sort) {
    return fallback ?? Order.none()
  }
  const orderType = sort.startsWith("-") ? "desc" : "asc"
  const orderBy = sort.startsWith("-") ? sort.slice(1) : sort
  return Order.fromValues(orderBy, orderType)
}
