# UX Rules / Copy / Design System

Este documento es ley. Todo UI debe cumplirlo.

## A) Principios
- 3 taps rule: registrar gasto/ingreso en <= 3 interacciones.
- No contabilidad: evitar jerga (débitos/créditos). Usar “Entró / Salió / Transferí”.
- Defaults inteligentes: fecha=hoy, última cuenta usada, categoría frecuente, moneda por cuenta.
- Feedback inmediato: siempre mostrar efecto (restante de categoría, neto del mes, etc.).
- Una pantalla = una decisión: sin formularios eternos.
- Undo: al borrar algo, ofrecer “Deshacer” (soft delete o restore rápido).
- Aprendizaje por uso: nada de tutorial largo; micro-hints contextuales.

## B) Copy (textos exactos)
Botones:
- Registrar gasto
- Registrar ingreso
- Transferir
- Guardar
- Listo

Estados:
- Pendiente
- Confirmado

Mensajes:
- Gasto registrado. Te quedan R$ X en {Categoría} este mes.

Errores:
- Falta elegir una cuenta
- El monto debe ser mayor que 0

## C) Formato de dinero y fechas
- Moneda BRL por defecto, formato pt-BR en UI (R$ 1.234,56)
- Fecha: dd/MM/yyyy en UI

## D) Componentes base Flutter
- AppScaffold + BottomNav
- PrimaryButton, SecondaryButton
- MoneyInput (con máscara)
- CategoryPicker (con búsqueda)
- AccountPicker
- QuickActionCard (dashboard)
- InlineSummaryCard (planned/actual/restante)
- Snackbar estándar con acción “Desfazer” cuando aplique
