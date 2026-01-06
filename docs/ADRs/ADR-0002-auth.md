# ADR-0002 — Auth + Multi-tenant (JWT + Refresh Rotation)

## Status
Accepted

## Context
Necesitamos autenticación real (register/login/refresh/logout/me) y multi-tenant basado en `userId` derivado del JWT. El sistema ya usa repositorios `MongoRepository<T>` y Clean Architecture.

## Decision
- Autenticación con JWT access token (15m) y refresh token (30 días).
- Refresh token rotation: cada refresh invalida el anterior.
- Refresh tokens guardados hasheados (SHA-256) en MongoDB.
- `userId` se obtiene únicamente del JWT via middleware.
- `USER_ID_DEFAULT` solo se permite en `dev/seed.ts`.

## Consequences
- Todas las rutas de dominio requieren `Authorization: Bearer <access>`.
- Los handlers usan `ctx.userId` (no `USER_ID_DEFAULT`).
- Refresh token reusado falla con "Sesión expirada, entra de nuevo".
- Se requiere configurar `JWT_SECRET`, `ACCESS_TOKEN_TTL`, `REFRESH_TOKEN_TTL`.
