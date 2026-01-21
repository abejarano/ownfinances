# OwnFinances

Monorepo para app de finanzas personales (Bun API + Flutter + MongoDB).

## Estructura
- apps/api: API Bun (bun-platform-kit + MongoDB)
- apps/flutter: Flutter (web + mobile)
- packages/shared: tipos/DTOs compartidos
- infra/docker: docker-compose mongodb
- docs: documentación (UX, ADRs, etc.)

## Requisitos
- Bun
- Flutter SDK
- Docker

## Setup rápido
```bash
bun install
```

## MongoDB
```bash
docker compose -f infra/docker/docker-compose.yml up
```

## API (Bun)
```bash
bun --cwd apps/api dev
```

## Flutter
```bash
cd apps/flutter
flutter pub get
flutter run -d chrome
```

Para móvil:
```bash
flutter run
```

## Endpoints base
- GET /health
- GET /meta
