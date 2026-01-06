# @abejarano/ts-mongodb-criteria — Notes (local node_modules)

Fuente: `apps/api/node_modules/@abejarano/ts-mongodb-criteria` (README + `dist/*.d.ts`).

## Export principales
Desde `dist/index.d.ts`:
- Criteria, Filters, Filter, FilterField, FilterOperator (Operator), FilterValue, Order, OrderBy, OrderType, Paginate
- MongoCriteriaConverter
- MongoRepository
- MongoClientFactory
- AggregateRoot

### Propósito (según tipos)
- `Criteria`: agrupa filtros, orden, y paginación (limit + page). Constructor: `new Criteria(filters, order, limit?, offset?)`.
- `Filters`: colección de `Filter`. `Filters.fromValues([...Map])`.
- `Filter`: `field`, `operator`, `value`. Se crea con `Filter.fromValues(map)`.
- `Operator`: enum de operadores: `=, !=, >, <, >=, <=, CONTAINS, NOT_CONTAINS, BETWEEN, OR, IN, NOT_IN`.
- `Order`: ordenamiento; `Order.fromValues(orderBy?, orderType?)`, `Order.asc`, `Order.desc`, `Order.none`.
- `Paginate<T>`: retorno paginado `{ nextPag, count, results }`.
- `MongoCriteriaConverter`: convierte `Criteria` a `{ filter, sort, skip, limit }` para Mongo.
- `MongoRepository<T extends AggregateRoot>`: repo base con `searchByCriteria` y `paginate`.
- `MongoClientFactory`: crea `MongoClient` usando env `MONGO_PASS`, `MONGO_USER`, `MONGO_DB`, `MONGO_SERVER` (mongodb+srv).
- `AggregateRoot`: clase base requerida por `MongoRepository`.

## Construcción de filtros y paginación

### Criteria desde query params
```ts
import { Criteria, Filters, Operator, Order } from "@abejarano/ts-mongodb-criteria";

const filters = Filters.fromValues([
  new Map([
    ["field", "userId"],
    ["operator", Operator.EQUAL],
    ["value", userId],
  ]),
  new Map([
    ["field", "kind"],
    ["operator", Operator.EQUAL],
    ["value", kind],
  ]),
  new Map([
    ["field", "name"],
    ["operator", Operator.CONTAINS],
    ["value", q],
  ]),
]);

const order = Order.fromValues("name", "asc");
const criteria = new Criteria(filters, order, limit, page);
```

### Paginación
`Criteria` calcula internamente `offset` con `(page - 1) * limit`.
El convertidor genera `skip` y `limit`:
```ts
import { MongoCriteriaConverter } from "@abejarano/ts-mongodb-criteria";

const mongoQuery = new MongoCriteriaConverter().convert(criteria);
// mongoQuery: { filter, sort, skip, limit }
```

### Rango de fechas
El operador `BETWEEN` acepta `{ start, end }` o `{ startDate, endDate }` o `{ from, to }`:
```ts
new Map([
  ["field", "date"],
  ["operator", Operator.BETWEEN],
  ["value", { start: new Date("2026-01-01"), end: new Date("2026-01-31") }],
])
```

## Conexión con Mongo

### MongoRepository (si se usa)
```ts
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";

class CategoryRepository extends MongoRepository<Category> {
  collectionName(): string {
    return "categories";
  }
}

const repo = new CategoryRepository();
const results = await repo.searchByCriteria(criteria);
const page = await repo.paginate(results);
```

Notas reales del paquete:
- `MongoRepository` usa `MongoClientFactory`, que depende de env `MONGO_PASS`, `MONGO_USER`, `MONGO_DB`, `MONGO_SERVER` y construye un `mongodb+srv://...`.
- Si no se usa Atlas, se puede usar `MongoCriteriaConverter` con un `MongoClient` propio (como en este proyecto).

## Paginate (estructura real)
```ts
export type Paginate<T> = {
  nextPag: string | number | null;
  count: number;
  results: Array<T>;
};
```

## Ejemplo mínimo en este proyecto (listado + filtros)
Ejemplo equivalente al endpoint `GET /categories`:
```ts
const filters = Filters.fromValues([
  new Map([
    ["field", "userId"],
    ["operator", Operator.EQUAL],
    ["value", userId],
  ]),
  new Map([
    ["field", "kind"],
    ["operator", Operator.EQUAL],
    ["value", kind],
  ]),
  new Map([
    ["field", "name"],
    ["operator", Operator.CONTAINS],
    ["value", q],
  ]),
]);

const criteria = new Criteria(filters, Order.fromValues(orderBy, orderType), limit, page);
const query = new MongoCriteriaConverter().convert(criteria);

const results = await collection
  .find(query.filter)
  .sort(query.sort)
  .skip(query.skip)
  .limit(query.limit)
  .toArray();

const count = await collection.countDocuments(query.filter);
const response = {
  nextPag: page * limit < count ? page + 1 : null,
  count,
  results,
};
```
