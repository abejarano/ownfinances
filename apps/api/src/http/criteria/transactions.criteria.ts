import { Criteria, Filters, FilterInputValue, Operator, Order } from "@abejarano/ts-mongodb-criteria";

export function buildTransactionsCriteria(
  query: Record<string, string | undefined>,
  userId: string,
): Criteria {
  const filters: Array<Map<string, FilterInputValue>> = [
    new Map<string, FilterInputValue>([
      ["field", "userId"],
      ["operator", Operator.EQUAL],
      ["value", userId],
    ]),
  ];

  if (query.dateFrom && query.dateTo) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "date"],
        ["operator", Operator.BETWEEN],
        ["value", { start: new Date(query.dateFrom), end: new Date(query.dateTo) }],
      ]),
    );
  } else if (query.dateFrom) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "date"],
        ["operator", Operator.GTE],
        ["value", new Date(query.dateFrom)],
      ]),
    );
  } else if (query.dateTo) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "date"],
        ["operator", Operator.LTE],
        ["value", new Date(query.dateTo)],
      ]),
    );
  }

  if (query.categoryId) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "categoryId"],
        ["operator", Operator.EQUAL],
        ["value", query.categoryId],
      ]),
    );
  }

  if (query.type) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "type"],
        ["operator", Operator.EQUAL],
        ["value", query.type],
      ]),
    );
  }

  if (query.status) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "status"],
        ["operator", Operator.EQUAL],
        ["value", query.status],
      ]),
    );
  }

  if (query.q) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "note"],
        ["operator", Operator.CONTAINS],
        ["value", query.q],
      ]),
    );
  }

  if (query.accountId) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "accountId"],
        ["operator", Operator.OR],
        [
          "value",
          [
            { field: "fromAccountId", operator: Operator.EQUAL, value: query.accountId },
            { field: "toAccountId", operator: Operator.EQUAL, value: query.accountId },
          ],
        ],
      ]),
    );
  }

  const limit = query.limit ? Number(query.limit) : 20;
  const page = query.page ? Number(query.page) : 1;
  const order = buildOrder(query.sort, Order.desc("date"));

  return new Criteria(Filters.fromValues(filters), order, limit, page);
}

function buildOrder(sort?: string, fallback?: Order): Order {
  if (!sort) {
    return fallback ?? Order.none();
  }
  const orderType = sort.startsWith("-") ? "desc" : "asc";
  const orderBy = sort.startsWith("-") ? sort.slice(1) : sort;
  return Order.fromValues(orderBy, orderType);
}
