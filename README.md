@"
# Timea (Android) — Gestor de inversión consciente (tiempo / recursos)

Timea es una app Android para metas/hábitos/proyectos enfocada en hacer visible:
- cuánto tiempo has invertido (días, horas, sesiones)
- qué recursos has gastado (dinero u otros)
- y ayudarte a tomar decisiones conscientes (continuar / pausar / extender / cerrar ciclo)

## Quick start
1) Revisar entorno:
   - `flutter doctor`
   - `.\scripts\check_env.ps1`

2) Correr en Android (emulador encendido):
   - `flutter devices`
   - `flutter run -d emulator-5554`

## Estructura
- `docs/architecture.md`: decisiones de arquitectura y organización
- `docs/features/*.md`: especificación por feature
- `ROADMAP.md`: plan por fases
- `CHANGELOG.md`: cambios por versión
- `scripts/`: atajos de entorno y ejecución

## Convención de commits
- `init:` arranque del repo/proyecto
- `docs:` documentación
- `feat:` nueva funcionalidad
- `fix:` bugfix
- `refactor:` reestructura

"@ | Set-Content -Encoding UTF8 README.md