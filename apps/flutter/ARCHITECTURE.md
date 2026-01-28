# ARCHITECTURE.md — Desquadra Flutter (Clean Architecture + Vertical Slice)

Objetivo: consistencia por feature, testabilidad y UX ultra simple.

---

## 0) Reglas de UX (mandatorias)
- 3 taps rule
- Defaults inteligentes (última cuenta/categoría)
- Feedback inmediato (snackbar con restante)
- Undo real (chama restore)
- pt-BR como idioma oficial
- Soluciones paliativas PROHIBIDAS (resolver causa raíz)

---

## 1) Estructura por feature (vertical slice)

lib/
  core/
    http/
      api_client.dart
      auth_interceptor.dart
    storage/
      token_storage.dart
      prefs_store.dart
    result/
      result.dart
      failure.dart
    routing/
      app_router.dart
    theme/
      app_colors.dart
      app_text_styles.dart
      app_spacing.dart
      app_radius.dart
    ui/
      components/ (PrimaryButton, MoneyInput, Pickers...)
      scaffold/ (AppScaffold + BottomNav)
  features/
    auth/
    setup/
    dashboard/
    transactions/
    budgets/
    accounts/
    categories/
    ...

---

## 2) Capas y dependencias

Presentation (Widgets)
→ Application (Controllers/Notifiers)
→ Domain (Entities + UseCases + Repo interfaces)
← Data (Repo impl + DTO + Mappers + Datasources)

Domain no importa Flutter, Riverpod, Dio.
Widgets deben ser reusables, pequenos y con un solo objetivo.

---

## 3) Contratos y modelos
- Flutter NO comparte tipos con TS.
- El contrato (OpenAPI) es la referencia.
- DTOs viven en Data, Entities en Domain.

---

## 4) HTTP y sesión

Requerido:
- ApiClient adjunta access token
- Si 401: intenta refresh UNA vez y reintenta
- Si refresh falla: logout + redirect login + mensagem "Sessão expirada"

Token storage:
- mobile: flutter_secure_storage
- web: localStorage con prefijo, expiración y limpieza

---

## 5) Estados (simple)
- Evitar mega-states.
- Preferir AsyncNotifier + estados pequeños.
- UI nunca muestra stack traces.

---

## 6) UX Defaults (core)
Guardar localmente:
- lastUsedAccountId por tipo
- lastUsedCategoryId por tipo
- lastPeriod (Este mês, etc.)

---

## 7) Testing mínimo
- Domain: use cases + value objects
- Data: mappers + repository (mock client)
- Application: controller/notifier con fake repos
