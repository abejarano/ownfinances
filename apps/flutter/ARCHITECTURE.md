Arquitectura base Flutter con Clean Architecture + OOP.
Objetivo: escalabilidad, testabilidad, y consistencia por features.

## Visión general

Usamos una variante de **Clean Architecture** organizada por **feature (vertical slice)**:

Presentation (Flutter UI)
-> Application (estado, coordinación)
-> Domain (negocio puro)
<- Data/Infrastructure (API, cache, storage)

### Reglas de dependencia

- Presentation depende de Application/Domain.
- Application depende de Domain.
- Domain no depende de nada externo (solo Dart puro).
- Data depende de Domain (implementa interfaces).
- Infra (HTTP, DB, storage) vive en Data o en `core/infrastructure`.

## Capas y responsabilidades

### 1) Domain

**Qué contiene**

- `Entity`: modelo del negocio (inmutable).
- `ValueObject`: validación y reglas pequeñas (ej: Email, Money).
- `Repository (interface)`: contratos del negocio.
- `UseCase`: una acción de negocio (ej: `Login`, `CreateTransaction`).
- `Failure`: errores de negocio/operación traducidos.

**Qué NO contiene**

- Widgets, Riverpod, Dio, SharedPreferences, Firebase, etc.

**Ejemplo de UseCase (conceptual)**

- `LoginUseCase.execute(email, password) -> Result<AuthSession, Failure>`

### 2) Data / Infrastructure

**Qué contiene**

- `DTOs` (json models), `Mappers` (DTO <-> Entity)
- `RemoteDataSource` (HTTP), `LocalDataSource` (cache/storage)
- Implementación de repositorios de Domain
- Interceptores, headers, refresh token, etc.

**Regla clave**

- Nunca retorna DTOs hacia arriba: siempre Entities/ValueObjects o `Result`.

### 3) Application (orchestración y estado)

**Qué contiene**

- Controllers / Notifiers / Cubits:
  - Llaman UseCases.
  - Transforman `Result` en estados.
- Modelos de estado:
  - `initial/loading/success/error/empty`
- Validación de formularios (si no está en ValueObjects)

**Regla clave**

- No hacer HTTP aquí.

### 4) Presentation (UI)

**Qué contiene**

- Screens, Widgets, UI states
- Navegación
- Diseño consistente con design system

**Reglas**

- Widgets “tontos”: solo leen estado, renderizan y disparan acciones.
- Nada de reglas de negocio en `build()`.

## Estructura de carpetas (recomendada)

lib/
core/
config/
di/
error/
routing/
theme/
utils/
features/
<feature_name>/
domain/
entities/
value_objects/
repositories/
use_cases/
failures/
data/
datasources/
dtos/
mappers/
repositories/
application/
controllers/
state/
presentation/
screens/
widgets/

## Data Flow típico

Ejemplo: “Crear transacción”

1. UI envía `onSubmit()` al controller.
2. Controller valida (o usa ValueObjects).
3. Controller llama `CreateTransactionUseCase`.
4. UseCase llama al `TransactionRepository` (interface).
5. Implementación en Data usa `RemoteDataSource` (HTTP) y/o `LocalDataSource`.
6. Data retorna `Result<Transaction, Failure>`.
7. Controller emite estado `success` o `error`.
8. UI renderiza.

## Manejo de errores y Result

Recomendación:

- Usar `Result<T>` (o `Either<Failure, T>`).
- `Failure` en Domain.
- Traducción:
  - `DioError/SocketException` -> `NetworkFailure`
  - `401/403` -> `UnauthorizedFailure`
  - `422` -> `ValidationFailure`
  - `500+` -> `ServerFailure`

UI nunca muestra excepciones crudas.

## Modelado OOP (práctico)

- Entities con invariantes claras.
- ValueObjects para validación (evitar “stringly-typed”):
  - `Email`, `Password`, `Money`, `TransactionId`
- Servicios de dominio solo cuando:
  - Hay lógica transversal que no pertenece a una entidad.
- Preferir composición (ej: `Transaction` contiene `Money amount`).

## Estado (Riverpod sugerido)

- `Notifier/AsyncNotifier` para orquestación.
- Estados explícitos:
  - `Loading`, `Ready(data)`, `Error(message)`, `Empty`
- Evitar mega-states con 30 flags. Preferir:
  - varios providers o estados pequeños.

## DI (inyección de dependencias)

Dos caminos válidos (elige uno):

1. **Riverpod providers** (preferido):

- `Provider<Dio>`
- `Provider<AuthRemoteDataSource>`
- `Provider<AuthRepository>`
- `Provider<LoginUseCase>`
- `NotifierProvider<AuthController, AuthState>`

2. **get_it** (si el proyecto ya lo usa)

- Mantener módulos por feature.

Regla: no mezclar sin una razón fuerte.

## Navegación

- Centralizar rutas en `core/routing/`.
- No “pushNamed” con strings hardcodeados por toda la app.
- Parametrizar con tipos cuando sea posible.

## UI / Design System

- `core/theme/` define:
  - `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`
- Componentes base:
  - `PrimaryButton`, `AppTextField`, `AppDialog`, `AppScaffold`
- Accesibilidad:
  - tamaños táctiles, contraste, `Semantics` donde aplique.

## Observabilidad (logs/analytics)

- Logger central en `core/logger/`.
- En Data loggear requests/responses (sin datos sensibles).
- En Application loggear eventos importantes (ej: “login_failed”).
- Evitar `print`.

## Seguridad

- Tokens en almacenamiento seguro (`flutter_secure_storage`).
- Nunca loggear tokens, passwords, PII.
- Validar inputs y sanitizar strings.
- Pinning SSL solo si es requerido por compliance.

## Checklist de calidad por feature

- [ ] UseCase(s) con tests
- [ ] Repositorio interface en Domain
- [ ] Repo impl + datasources + mapper en Data
- [ ] Controller/Notifier con estados claros
- [ ] UI sin lógica de negocio
- [ ] `dart analyze` sin warnings y `dart format` aplicado

## Decisiones (ADR ligera)

Para cambios arquitectónicos grandes:

- Crear `docs/adr/000X-title.md` con:
  - Contexto, Decisión, Consecuencias, Alternativas
