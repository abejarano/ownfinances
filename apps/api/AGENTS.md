# AGENTS.md — Reglas para Codex / Agentes (OBLIGATORIO)

Monorepo:

- `apps/api` (Bun + TypeScript + MongoDB)
- `apps/flutter` (Flutter web + mobile)
- `contracts/` (OpenAPI/contratos neutrales)
- `infra/docker` (docker-compose MongoDB)
- `docs/` (ux + arquitectura + ADRs)

---

## 1) Regla #1: NO inventes APIs ni comportamiento

- Si una librería no está clara (ej: `@abejarano/ts-mongodb-criteria`), **lee `node_modules` y `.d.ts`**.
- Si un endpoint no existe, créalo con contrato claro.
- Si falta definir un comportamiento, registra la decisión en `docs/ADRs/`.

---

## 2) Regla #2: UX primero (cumplir docs/ux.md)

Producto debe ser absurdamente fácil:

- “3 taps rule”
- Defaults inteligentes
- Feedback inmediato con “restante” y neto del periodo
- Sin jerga contable

Si un cambio rompe `docs/ux.md`, el cambio está mal.

---

## 3) Regla #3: Presupuesto NO se “rebaja”

`budgets` guarda SOLO planned.
`actual/remaining/progress` se calcula SIEMPRE desde `transactions` por periodo.
Crear/editar/eliminar transacciones cambia reportes por recálculo, no por mutación del budget.

---

## 4) Contratos entre backend y Flutter

NO hay “tipos compartidos” TS↔Dart.

Source of truth:

- OpenAPI en `contracts/` (o generado por el backend).

Reglas:

- Todo endpoint nuevo debe reflejarse en OpenAPI.
- Si se usa codegen para Flutter, mantenerlo actualizado.

---

## 5) Backend: reglas obligatorias

- Endpoints listables SIEMPRE usan `@abejarano/ts-mongodb-criteria` (Criteria/Paginate).
- Validación estricta de DTOs con mensajes humanos.
- Multi-tenant: todo filtrado por `userId`.
- Preferir soft delete + Undo en UI cuando aplique.

---

## 6) Flutter: reglas obligatorias

- Flujos cortos (<= 3 pasos para registrar).
- Summary visible y feedback post-guardar.
- Loading/Error states siempre.
- No hardcodear estructuras: seguir contrato (OpenAPI o modelos locales consistentes).

---

## 7) Definition of Done

- Compila y corre (API + Flutter).
- Respeta UX (`docs/ux.md`).
- Presupuesto calculado (no mutación).
- List endpoints con Criteria.
- Filtra por userId.
- Docs/ADR actualizado si cambió contrato o comportamiento.

## Backend — Uso obligatorio de @abejarano/ts-mongodb-criteria (Patrón REPO)

La forma oficial de usar `@abejarano/ts-mongodb-criteria` en este repo es:

- **Crear repositorios que extiendan `MongoRepository<T>`**
- Implementar interfaces de dominio (`I<Entidad>Repository`)
- En endpoints/handlers, **nunca** usar `db.collection().find()` directamente para listados.
- Los listados deben ser `repo.list(criteria)` y retornar `Paginate<T>`.
- IDs de dominio son `<entidad>Id`, las entidades incluyen `id?: string` y `getId()` retorna `id` para `persist`.
- Repos exponen `upsert(entity)` y `one(filter)` (no `create/update/findById`).
- NUNCA usar `USER_ID_DEFAULT` fuera de `dev/seed.ts`; los handlers toman `userId` del middleware JWT.
- Con Elysia, priorizar paquetes oficiales del framework (ej: `@elysiajs/jwt`) sobre librerías genéricas externas.

Ejemplo (patrón obligatorio):

```ts
import {
  MongoRepository,
  Criteria,
  Paginate,
} from "@abejarano/ts-mongodb-criteria";
import { MovementBank } from "@/Banking/domain";

export class MovementBankMongoRepository extends MongoRepository<MovementBank> {
  collectionName(): string {
    return "movement_banks";
  }

  async upsert(movementBank: MovementBank): Promise<void> {
    await this.persist(movementBank.getId(), movementBank);
  }

  async one(filter: object): Promise<BankStatement | undefined> {
    const collection = await this.collection();
    const result = await collection.findOne(filter);

    if (!result) {
      return undefined;
    }

    return MovementBank.fromPrimitives(result as any);
  }

  async list(criteria: Criteria): Promise<Paginate<MovementBank>> {
    const documents = await this.searchByCriteria<any>(criteria);
    const pagination = await this.paginate(documents);

    return {
      ...pagination,
      results: pagination.results.map((doc) =>
        MovementBank.fromPrimitives({ ...doc, id: doc._id })
      ),
    };
  }
}
```

```

## 8) Regla STRICT de AggregateRoot (ID vs EntityID)

Toda clase que extienda `AggregateRoot` DEBE seguir este patrón estricto:

1.  **Separación de IDs**:
    -   `id?: string`: Es el `_id` de MongoDB (persistencia). Opcional porque al crear no existe.
    -   `entityId: string`: ID de negocio/dominio (ej: `userId`, `transactionId`, `ruleId`). Es el que identifica la entidad en la app.
2.  **Constructor y Primitivos**:
    -   El tipo `Primitives` debe reflejar esto (`id?` y `entityId`).
3.  **Repositorios**:
    -   Las búsquedas por ID de negocio deben ser explícitas (ej: `findOne({ ruleId: ... })`).
    -   `getId()` del AggregateRoot debería retornar el `id` de Mongo si existe, o manejar la lógica de persistencia.

Ejemplo correcto:

```ts
export class User extends AggregateRoot {
  // id?: string; // Mongo ID
  // userId: string; // Domain ID
  getId(): string {
     return this.props.id ?? this.props.userId; // O lo que requiera la lib para persistir
  }
}
```

## Data Access Layer (DAL) — Repositorios con MongoRepository<T>

Acceso a datos se hace mediante repositorios que extienden:

- `MongoRepository<T>` de `@abejarano/ts-mongodb-criteria`

Patrón:

- Cada entidad tiene `I<Entity>Repository` (dominio) y `EntityMongoRepository` (infra).
- Listados/paginación/filtros se resuelven con `Criteria` y `Paginate` dentro del repo.
- Handlers/controladores NO hacen `collection.find()` para listados.
