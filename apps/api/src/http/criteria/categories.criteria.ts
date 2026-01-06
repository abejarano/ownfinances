import { Criteria, Filters, FilterInputValue, Operator, Order } from "@abejarano/ts-mongodb-criteria";

export function buildCategoriesCriteria(query: Record<string, string | undefined>, userId: string) {
  const filters: Array<Map<string, FilterInputValue>> = [
    new Map<string, FilterInputValue>([
      ["field", "userId"],
      ["operator", Operator.EQUAL],
      ["value", userId],
    ]),
  ];

  if (query.kind) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "kind"],
        ["operator", Operator.EQUAL],
        ["value", query.kind],
      ]),
    );
  }

  if (query.isActive !== undefined) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "isActive"],
        ["operator", Operator.EQUAL],
        ["value", query.isActive === "true"],
      ]),
    );
  }

  if (query.q) {
    filters.push(
      new Map<string, FilterInputValue>([
        ["field", "name"],
        ["operator", Operator.CONTAINS],
        ["value", query.q],
      ]),
    );
  }

  const limit = query.limit ? Number(query.limit) : 20;
  const page = query.page ? Number(query.page) : 1;
  const order = buildOrder(query.sort, Order.asc("name"));

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
