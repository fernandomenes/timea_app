# Feature: Timer

## Estado actual
Implementado en versión MVP:
- iniciar sesión
- pausar
- reanudar
- detener y guardar
- persistencia local de sesiones completadas
- historial de sesiones por meta

## Limitaciones actuales
- si cierras la app a media sesión, la sesión activa no se recupera
- no hay notificación persistente todavía
- no hay temporizador en segundo plano real

## Modelo actual
- id
- goalId
- startedAt
- endedAt
- effectiveSeconds