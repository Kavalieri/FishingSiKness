# Stub de Ads Recompensados — Fishing SiKness

## Implementación
- Sistema `StoreSystem.gd` con señales para compra, recompensa y errores.
- Límite de 10 anuncios por día y cooldown de 10 minutos entre anuncios.
- Simulación de recompensa y error por límites/cooldown.

## Contrato
- Señales: `ad_reward_requested(placement)`, `reward_granted(id)`, `store_error(msg)`
- Función: `show_ad(placement)`

## Pruebas
- Se ha probado la emisión de señales y el control de límites.
- Listo para integración con UI y validación en QA.

## Referencias
- GDD sección 13.
- Tasklist Fase 1 Prevalidación, punto 4.
