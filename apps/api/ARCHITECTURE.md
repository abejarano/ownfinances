# ARCHITECTURE.md — Desquadra API (Bun + bun-platform-kit + Mongo)

Objetivo: API estable, multi-tenant real, Clean Architecture estricta, contratos consistentes y UX-friendly.

---

## 0) Reglas de producto (NO negociables)

- UX sin contabilidad: términos simples, errores humanos (pt-BR).
- Budgets guardan SOLO planned. Actual/remaining siempre se recalcula desde transactions.
- Undo real: soft delete + restore.
- Multi-tenant: todo filtrado por userId desde JWT.
- Fecha de transacción es "YYYY-MM-DD" (string local) para evitar timezone bugs.
- MVP: BRL-only para reportes (no sumar monedas distintas).

---

## 1) Clean Architecture (dependencias)

HTTP (bun-platform-kit)
→ Controllers (Interface Adapters) with decoration for define routes.
→ Services (Use Cases)
→ Models (Entities + Rules + Interfaces)
← Infrastructure (Mongo Repos)

Regla #1: Models no depende de nada externo.
Regla #2: Valores fijos se definen con `enum`; `type` se usa para shapes.
Regla #3: AggregateRoot usa `static create(...)`; no se instancia con `new` ni se crea `id` manual.
Regla #4: IDs se generan dentro del modelo (services no generan ids).
Regla #5: IDs deben ser `createMongoId()` (24 hex) para compatibilidad con MongoRepository.

---

## 2) Estructura obligatoria

apps/api/src/
main.ts
bootstrap/
app.ts
deps.ts
mongo.ts
http/
routes/
controllers/
middleware/
criteria/
presenters/
errors.ts
application/
services/
models/
auth/
category/
account/
transaction/
budget/
report/
...
repositories/
dev/
seed.ts
contracts/
openapi.snapshot.json (generado)

---

## 3) Contrato de respuestas (OBLIGATORIO)

### 3.1 Éxito

- GET list: Paginate<Primitives>
- GET by id / POST / PUT: Primitives
- Acciones: { ok: true } o payload explícito

Paginate<T> (shape estable):
{
"results": T[],
"page": number,
"limit": number,
"total": number,
"pages": number
}

### 3.2 Error (siempre igual)

{
"error": string,
"code"?: string
}

Status:

- 400 validation
- 401 not authenticated
- 403 not authorized (si aplica)
- 404 not found
- 409 conflict (email already registered)
- 500 unexpected

---

## 4) Modelado: dinero y fechas

### 4.1 Transaction.date

- Guardar como string "YYYY-MM-DD" (local date)
- createdAt/updatedAt: ISO string UTC

### 4.2 Amount

Recomendación:

- usar amountMinor (centavos) como int, y exponer amount en UI con formatter
  Si todavía usas number, documentar ADR y evitar floats peligrosos.

---

## 5) Seguridad mínima

- Access token ~15min
- Refresh token ~30d, guardado hasheado, rotation obligatoria
- CORS habilitado para Flutter web
- Rate limit en /auth/\* (básico)
- No loggear tokens/PII

---

## 6) Repositorios y Criteria (OBLIGATORIO)

- Repos Mongo viven en `/src/repositories` y extienden MongoRepository<T> de @abejarano/ts-mongodb-criteria
- La libreria ya trae `one`, `list` y `upsert`: se usan esos metodos y no se crean `findBy...`
- No crear interfaces de repositorio propias cuando se usa el repo Mongo directamente
- Listados siempre con Criteria/Paginate (usar `list`, nunca `search`)
- OR compuesto solo si la lib lo soporta; si no:
  - workaround dentro del repo
  - ADR obligatoria

## 6.1) Validacion (TypeBox)

- Cada nuevo endpoint debe evaluarse si requiere validate con TypeBox.
- La validacion de request vive en el router, no en services.
- No usar `unknown` en tipos; contratos de request siempre tipados.
- Los casos de uso (services) viven en `/src/application/services`.

---

## 7) Reportes (reglas)

- /reports/summary por defecto usa status=cleared
- permite includePending=true
- budgets: planned only
- remaining = planned - actual (negativo si superado)

Agregar:

- /reports/accounts/balances (por cuenta y moneda)
- opcional: /reports/categories/top

---

## 8) Undo (soft delete)

- DELETE /transactions/:id set deletedAt
- POST /transactions/:id/restore limpia deletedAt
- list excluye deletedAt por defecto (includeDeleted=true opcional)

---

## 9) OpenAPI (source of truth)

- Generar OpenAPI automáticamente
- Guardar snapshot en /contracts/openapi.snapshot.json
- Flutter puede hacer codegen si deseas, pero contrato manda.

---

## 10) Observabilidad

- Logger central
- Request logs sin datos sensibles
- Correlation id por request (si es posible)
