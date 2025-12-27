# Notas de Migración

## Cambios Principales
- **Separación de Lógica**: `_MainScreenState` ha sido desmantelado. La lógica de negocio ahora reside en `WorkoutProvider` y `WorkoutService`.
- **Modelos con Lógica**: Los modelos ya no son simples POJOs (Plain Old Java Objects). Ahora incluyen métodos para calcular volumen, puntuación de récords y duración.
- **Inyección de Dependencias**: Se utilizará `Provider` para la mayoría de los casos de uso, simplificando la propagación de datos.

## Bugs Corregidos (Legacy)
- *A completar durante la implementación:*
- [ ] Manejo de decimales en inputs (comas vs puntos).
- [ ] Persistencia de estados intermedios del timer.
- [ ] Consistencia de récords personales tras borrar sesiones.
