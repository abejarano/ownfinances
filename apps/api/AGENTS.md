# AGENTS.md — Backend (Bun + Elysia + Mongo) — Desquadra

Meta: código limpio, sin “god files”, contratos consistentes, UX-first.

---

## 1) No inventes APIs (regla #1)

- Si usas @abejarano/ts-mongodb-criteria: leer node_modules y .d.ts.
- Si una decisión no está definida: crear ADR en docs/ADRs/.

---

## 2) Prohibiciones (hard rules)

- PROHIBIDO: lógica de negocio en routes/controllers.
- PROHIBIDO: Mongo find() para listados en handlers.
- PROHIBIDO: repos con `search(criteria)` si se quiere impletar para pagianr datos; usar siempre `list(criteria)` -> `Paginate`.
- PROHIBIDO: métodos que retornan 1 registro fuera de `one` (no `findBy...`).
- PROHIBIDO: `collection.findOne(...)` en repos; si necesitas 1 documento usa `repo.one({ ... })` y ajusta el modelo/consulta para que sea igualdad simple.
- PROHIBIDO: crear wrappers tipo `oneByX(...)`/`findOneByX(...)` en repos o services; usa `repo.one({ ... })` directamente en el service/controller.
- PROHIBIDO: updates/inserts fuera de `upsert`.
- PROHIBIDO: USER_ID_DEFAULT fuera de dev/seed.ts.
- PROHIBIDO: respuestas inconsistentes (a veces entity, a veces primitives).
- PROHIBIDO: validar payload en service; el validate va en router.
- PROHIBIDO: usar `unknown` en tipos; todo request debe tener contrato tipado.
- PROHIBIDO: validar en servicios; los validate viven en `http` como pre-handler en routes.
- PROHIBIDO: usar string unions para valores fijos; usar `enum` y `type` solo para shapes.
- PROHIBIDO: crear interfaces de repositorios propias si ya se usa el repo Mongo directamente.
- PROHIBIDO: instanciar AggregateRoot con `new`; usar `Model.create(...)`.
- PROHIBIDO: crear manualmente `id` del documento (Mongo lo genera).

---

## 3) Contrato de respuesta obligatorio

- List => Paginate<Primitives>
- Get/Create/Update => Primitives
- Error => { error, code? }

---

## 4) Flujo de implementación (siempre igual)

1. Models:
   - Entity + types (sin interfaces de repositorio extra)
   - `static create(...)` para nuevos (constructor privado)
   - IDs se generan dentro del modelo (nunca en services)
   - usar `createMongoId()` para ids de entidades
2. Application:
   - Service con reglas (defaults + validación merge)
3. Repositories (`/src/repositories`):
   - MongoRepository<T> usando `one`, `list` y `upsert` (nunca search, nunca findBy)
4. HTTP:
   - criteria mapper (query -> Criteria)
   - validate en router (pre-handler) -> controller -> service -> presenter
5. OpenAPI snapshot actualizado
6. Tests mínimos

---

## 5) Checklist por PR (DoD)

- [ ] respeta Clean Architecture
- [ ] endpoints list usan Criteria/Paginate
- [ ] cada nuevo endpoint fue evaluado para validate (TypeBox) cuando aplica
- [ ] multi-tenant por ctx.userId
- [ ] errores humanos pt-BR
- [ ] undo (soft delete + restore) donde aplique
- [ ] openapi snapshot actualizado
- [ ] no logs de tokens

---

## 6) Decisiones obligatorias del producto

- budgets = planned only
- report summary default cleared
- transaction.date = "YYYY-MM-DD"
- MVP BRL-only para reportes (no sumar monedas)
