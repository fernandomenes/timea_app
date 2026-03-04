@"
# Arquitectura (inicial)

## Principios
- Modularidad: una feature por carpeta.
- Cambios pequeños: 1–3 archivos por entrega.
- Persistencia local primero (sin backend).
- Antes de avanzar: compila y corre en Android.

## Features
- goals: metas/hábitos/proyectos
- journal: registros diarios
- timer: sesiones
- balance: totales y resúmenes
- notifications: integración Android (después)

## Organización prevista (cuando pasemos del demo a nuestra base)
lib/
  app/
  core/
  features/
    goals/
    journal/
    timer/
    balance/
    notifications/

"@ | Set-Content -Encoding UTF8 docs\architecture.md