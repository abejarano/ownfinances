# ARCHITECTURE.md — Clean Architecture (Personal Finance)

Este proyecto debe mantenerse **Clean Architecture**.
La meta es evitar “God files”, evitar lógica en handlers, y asegurar que el dominio sea estable.

---

## 1) Principios (Clean Architecture)

### 1.1 Regla de dependencias (la más importante)

Las dependencias SIEMPRE apuntan hacia adentro:

**HTTP / Framework (Elysia)**  
→ **Controllers (Interface Adapters)**  
→ **Application Services (Use Cases)**  
→ **Domain (Entities + Rules)**

- El **Domain** no depende de nada externo (ni Mongo, ni Elysia, ni libs de infra).
- **Application** conoce interfaces de repositorios, pero NO implementaciones concretas.
- **Infrastructure** implementa repositorios (Mongo) y se conecta a DB.
- **HTTP** solo orquesta: request → use case → response.

---

## 2) Estructura de carpetas (OBLIGATORIA)

apps/api/src/
main.ts # entrypoint minimal: crea app y listen
bootstrap/
app.ts # configura Elysia + rutas + plugins
mongo.ts # connect MongoClient + shutdown hooks
deps.ts # DI simple: instancia repos + services
http/
routes/ # define endpoints (Elysia)
controllers/ # controllers: parse/validate input + llama use cases
criteria/ # query -> Criteria (ts-mongodb-criteria)
presenters/ # mapea domain -> response (toPrimitives)
errors.ts # helpers: badRequest/notFound
application/
services/ # use cases: reglas, defaults, validación cross-entity
domain/
category/
account/
transaction/
... # entities, value objects, interfaces de repos
infrastructure/
repositories/ # MongoRepository<T> implementations
dev/
seed.ts # seeds solo dev

markdown
Copiar código

> Nota: el folder `infrastructure/` puede llamarse `repositories/` si ya existe, pero debe representar **infra** (Mongo).  
> Lo importante: **HTTP nunca debe contener lógica de dominio ni queries Mongo directas.**

---

## 3) Responsabilidades por capa

### 3.1 Domain

Contiene:

- Entidades (`Category`, `Account`, `Transaction`)
- Tipos y Value Objects (ej: `CategoryKind`, `TransactionType`)
- Interfaces de repositorio (ej: `ICategoryRepository`)

Prohibido en Domain:

- `MongoClient`, `Elysia`, `Criteria`, `Filters`, `.env`, `process`, crypto randomUUID (puede estar en factory outside)

### 3.2 Application (Use Cases / Services)

Contiene:

- Reglas de negocio “reales” (ej: validación create/update con merge)
- Defaults (fecha=hoy, currency por cuenta)
- Coordinación entre repos (ej: validar que accountId exista)
- Operaciones atómicas: create/update/delete/clear
- Casos de uso por entidad (ej: `CategoriesService`, `AccountsService`, `TransactionsService`)

Prohibido en Application:

- conocimiento de HTTP/Elysia (no `set.status`, no `query`, no `params`)
- construir `Criteria` a partir de query string

### 3.3 Infrastructure (Mongo)

Contiene:

- Implementaciones concretas de repositorios
- Acceso a MongoDB

Regla obligatoria para esta app:

- Repositorios deben extender `MongoRepository<T>` de `@abejarano/ts-mongodb-criteria`

### 3.4 HTTP (Routes/Controllers)

Contiene:

- Rutas Elysia
- Controllers con:
  - parse de query/body/params
  - validación “de forma” (required fields básicos, tipos)
  - creación de `Criteria` usando mappers en `http/criteria`
  - llama services y devuelve response

Prohibido en HTTP:

- lógica de negocio (ej: “si es expense requiere categoryId”)
- queries Mongo directas
- seeds
- construir pipelines de agregación (eso es infra o application)

---

## 4) Regla crítica: Presupuesto NO se “rebaja”

`budgets` guarda SOLO `planned`.

La ejecución se calcula desde `transactions`:

- `actual` = sum(transactions) por periodo + categoría
- `remaining` = planned - actual
- create/update/delete transacción cambia reportes por recálculo, NO por mutación del budget

---

## 5) Regla obligatoria: uso de @abejarano/ts-mongodb-criteria

### 5.1 El patrón correcto es Repository + MongoRepository<T>

La forma oficial es implementar repositorios así:

- Los IDs de dominio deben ser `<entidad>Id` (ej: `categoryId`, `accountId`, `transactionId`).
- Las entidades deben incluir `id?: string` y `getId()` debe retornar ese `id` para `persist`.
- Repositorios exponen `upsert(entity)` (usa `persist`) y `one(filter)`. No usar `create/update/findById`.

```ts
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { IMovementBankRepository, MovementBank } from "@/domain/movement/...";

export class MovementBankMongoRepository
  extends MongoRepository<MovementBank>
  implements IMovementBankRepository
{
  collectionName(): string {
    return "movement_banks";
  }

  async list(criteria: Criteria): Promise<Paginate<MovementBank>> {
    const documents = await this.searchByCriteria<MovementBank>(criteria);
    const pagination = await this.paginate(documents);

    return {
      ...pagination,
      results: pagination.results.map((doc) =>
        MovementBank.fromPrimitives({ ...doc, id: doc._id })
      ),
    };
  }

  async one(filter: object): Promise<MovementBank | undefined> {
    const collection = await this.collection();
    const result = await collection.findOne(filter);

    if (!result) {
      return undefined;
    }

    return BankStaMovementBanktement.fromPrimitives(result as any);
  }

  async upsert(movement: MovementBank): Promise<void> {
    await this.persist(movement.getMovementBankId(), movement);
  }
}
```

### 5.2 Listados con Criteria

Todo endpoint GET listable debe usar repo.list(criteria) y retornar Paginate<T>.

El mapping query -> Criteria vive en http/criteria/\*.

Prohibido usar collection.find() en handlers para listados.

Si algún filtro complejo (ej: OR compuesto) no está soportado por la lib:

se encapsula en el repositorio (infra)

se documenta en ADR

handlers siguen llamando al repo (no construyen queries Mongo).

## 6. Flujo típico (ejemplo)

Create Transaction (ejemplo de flujo)
Route: POST /transactions (Elysia)

Controller:

valida shape básico del payload

llama TransactionsService.create(userId, payload)

Service (Application):

aplica defaults (date hoy, currency por cuenta)

valida reglas (income/expense/transfer)

valida existencia de cuentas

crea entidad

llama repo.create(entity)

Repo (Infrastructure):

persiste en Mongo

Presenter:

retorna transaction.toPrimitives() (response consistente)

## 7. Reglas de consistencia de respuestas (API contract)

Siempre devolver primitives (DTO), no entidades crudas.

Mismo shape en create/get/list.

Ej:

GET /categories/:id devuelve CategoryPrimitives

GET /categories devuelve Paginate<CategoryPrimitives>

## 7.1 Regla de userId

- `USER_ID_DEFAULT` solo se usa en `dev/seed.ts`.
- Todas las rutas de dominio usan `ctx.userId` desde middleware JWT.

## 8. Anti-patrones (prohibidos)

“God file” tipo index.ts con todo adentro.

Validación de update sin merge (permite estados inválidos).

Queries Mongo directas en handlers.

Mezclar seed con producción.

Respuestas inconsistentes (a veces entity, a veces primitives).

## 9. ADR (decisiones)

Toda decisión no obvia debe ir en docs/ADRs/:

OR compuesto en Criteria

incluir/excluir pending en reportes

estrategia de dedupe CSV

yaml
Copiar código

---

## ✅ 2) Patch para `AGENTS.md` (añadir sección “Clean Architecture enforcement”)

Pega esto en AGENTS.md (arriba de backend rules):

```md
## Clean Architecture (ENFORCEMENT)

- Está prohibido meter lógica de negocio en `main.ts`, `index.ts` o en rutas.
- `main.ts` solo debe bootstrapping (createApp + listen).
- Controllers orquestan; Services contienen reglas; Repos acceden a Mongo.
- `http/criteria/*` es el único lugar donde se transforma query params -> Criteria.
- Repos Mongo deben extender `MongoRepository<T>` (ts-mongodb-criteria). No inventar otro p
```
