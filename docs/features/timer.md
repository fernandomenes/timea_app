@"
# Feature: Journal

Entradas por día asociadas a una meta.

Modelo inicial:
- id
- goalId
- date (YYYY-MM-DD)
- text
- minutesSpent (opcional)
- moneySpent (opcional)

Listo cuando:
- Crear/editar entrada
- Persistencia local ok

"@ | Set-Content -Encoding UTF8 docs\features\journal.md