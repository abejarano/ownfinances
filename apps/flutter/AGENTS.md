# AGENTS.md — Flutter (Desquadra)

Meta: consistencia visual + arquitectura limpia + UX absurdamente fácil.

---

## 1) Reglas innegociables
- UI -> Application -> Domain -> Data
- Domain no depende de Flutter
- Nada de lógica de negocio en Widgets
- pt-BR copy (según docs/ux.md)
- Widgets reusables, pequenos y con un solo objetivo
- Soluciones paliativas PROHIBIDAS (atacar causa raíz)
- Separar validaciones y reglas de negocio fuera de los widgets, delegándolas a helpers o servicios que toman el estado y devuelven decisiones claras; la UI solo debe renderizar y reaccionar.

---

## 2) Proceso obligatorio antes de crear algo
1) Buscar 2 ejemplos existentes (grep)
2) Leerlos completos
3) Copiar el patrón exacto
4) Implementar SOLO la variación necesaria

---

## 3) Contratos de API
- No inventar campos
- Si falta algo (impact, restore, balances), abrir issue/ADR y coordinar backend

---

## 4) Checklist por feature
- [ ] Domain: entities + repo interface + use case
- [ ] Data: dto + mapper + repo impl + datasource
- [ ] Application: controller/notifier + estados
- [ ] Presentation: screen + widgets
- [ ] Loading/Empty/Error states
- [ ] 3 taps rule cumplida
- [ ] snackbar feedback + undo si aplica

---

## 5) Performance web
- Listas con paginación real (Paginate)
- Evitar rebuilds gigantes
