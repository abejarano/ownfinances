Guía para agentes de desarrollo (LLMs) y colaboradores humanos.
Objetivo: mantener calidad de código, Clean Architecture, OOP sólido y consistencia en Flutter.

## Principios innegociables

- **Arquitectura limpia por feature**: UI -> Application -> Domain -> Data (o Infra).
- **Dependencias solo hacia adentro** (UI depende de App/Domain; Domain no depende de Flutter).
- **Código legible > “clever code”**.
- **Cambios pequeños, testeables y con intención clara**.
- **Nada de lógica de negocio en Widgets**.

## Stack recomendado (ajustable)

- State management: **Riverpod** (preferible) o BLoC (si ya existe).
- DI: Riverpod providers o `get_it` (uno solo, no mezclar sin razón).
- HTTP: `dio` o `http` (uno solo).
- Serialización: `freezed` + `json_serializable`.
- Lints: `flutter_lints` + reglas adicionales (ver sección Lints).

## Convenciones de código (Flutter/Dart)

- **Dart style** estándar (`dart format`).
- Nombres:
  - Clases: `PascalCase`
  - Archivos: `snake_case.dart`
  - Métodos/variables: `camelCase`
- Evitar `dynamic`. Preferir `sealed`, `union types` (Freezed) o genéricos.
- Preferir **inmutabilidad**:
  - Entities/ValueObjects inmutables.
  - `copyWith` para cambios.
- Preferir **composición** sobre herencia (OOP bien aplicado).

## Reglas de arquitectura (obligatorias)

### Domain

- Contiene: `entities`, `value_objects`, `repositories` (interfaces), `use_cases`, `failures`.
- **No** importa Flutter, `dio`, `shared_preferences`, etc.
- **UseCases**:
  - Un caso de uso por acción del usuario/negocio.
  - Métodos pequeños, con nombres expresivos.
  - Retornan `Result/Either` (o lanzan excepciones de dominio bien definidas, pero preferir `Result`).

### Data/Infrastructure

- Implementa repositorios del Domain.
- Mapea DTOs <-> Entities.
- Maneja cache, storage, API, DB.
- Nunca filtra DTOs hacia Domain/UI.

### Application (orchestration)

- Coordinación entre UI y Domain:
  - Controllers / Notifiers / Cubits.
  - Manejo de estados (loading/success/error/empty).
- Sin llamadas directas a `dio/http` (eso es Data).

### Presentation (UI)

- Widgets puros y declarativos.
- Validaciones de formulario: en Application (o ValueObjects en Domain).
- Cualquier cálculo no trivial: extraer a helpers/formatters o a Application.

## Estructura de carpetas (por feature)

Ejemplo recomendado:

lib/
core/
error/
result.dart
failure.dart
exceptions.dart
logger/
config/
di/
theme/
routing/
utils/
features/
auth/
domain/
data/
application/
presentation/
transactions/
domain/
data/
application/
presentation/

Reglas:

- Nada de `services/` genérico con 200 cosas adentro.
- Cada feature es “vertical slice”.

## Manejo de errores (estándar)

- Domain define `Failure` (ej: `NetworkFailure`, `ValidationFailure`, `UnauthorizedFailure`).
- Data traduce errores técnicos -> `Failure`.
- UI solo renderiza estados y mensajes user-friendly (mapping en Application).

## Testing (mínimos por PR)

- Domain: tests de UseCases y ValueObjects.
- Data: tests de mappers y repositorios (mock del client).
- Application: tests de controllers/notifiers (con fake repos).
- UI: golden tests solo si el diseño es crítico.

Comandos típicos:

- `flutter test`
- `dart format .`
- `dart analyze`

## Performance y buenas prácticas

- Evitar rebuilds gigantes: usar `const`, `Consumer`/selectors, `ListView.builder`, etc.
- No usar `setState` para lógica compleja.
- Evitar lógica en `build()`.

## UI/Design system

- Centralizar colores/typography:
  - `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`.
- No hardcodear estilos repetidos en widgets.
- Componentes reutilizables en `core/presentation/` (ej: buttons, inputs, dialogs).

## Pull Requests (cómo debe trabajar el agente)

1. Definir objetivo y alcance (qué se toca y qué no).
2. Implementar vertical slice mínimo (Domain->Data->App->UI).
3. Agregar tests mínimos.
4. `dart format` + `dart analyze` sin warnings.
5. Dejar notas de decisiones (breve) en la descripción del PR.

## Plantilla “Agregar nueva funcionalidad”

Checklist:

- [ ] Crear carpeta `features/<feature>/...`
- [ ] Domain: entity/value objects + repo interface + use case
- [ ] Data: dto + mapper + repo impl + datasources
- [ ] Application: controller/notifier + estados
- [ ] Presentation: screens/widgets
- [ ] Rutas y DI
- [ ] Tests mínimos

## Lints recomendados (extra)

Sugerido añadir en `analysis_options.yaml`:

- `always_declare_return_types`
- `avoid_print`
- `prefer_final_locals`
- `avoid_dynamic_calls`
- `unawaited_futures` (si aplica)
- `public_member_api_docs` (opcional)
