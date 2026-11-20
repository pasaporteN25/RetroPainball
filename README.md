# Pinball Temático

Pinball para Android (vertical, a pantalla casi completa) con mesas temáticas.
Motor: **Godot 4.7.2** (GDScript), renderer *Compatibility* para cubrir la mayor cantidad de teléfonos.

Estado: **Fase 1, prototipo de física** con formas simples. Ya funcionan los flippers, el lanzador,
los bumpers, los slingshots, el drenaje, las 3 bolas, el salvavidas, el display de 7 segmentos,
la pausa y el récord local.

## Correrlo

1. Abrí Godot 4.7.2 → *Importar* → elegí `project.godot`.
2. **F5** para jugar. En la PC, el mouse simula el touch.

| Acción | Touch | Teclado | Mando |
|---|---|---|---|
| Flipper izquierdo | mitad izquierda de la parte baja | `Z` `A` `←` | L1 |
| Flipper derecho | mitad derecha de la parte baja | `M` `L` `→` | R1 |
| Lanzar (mantener = cargar) | mitad derecha, con la bola en el carril | `Espacio` `↓` `Enter` | A |
| Pausa | botón `II` arriba / atrás de Android | `Esc` `P` | Start |

## Tests (definición de hecho)

Un solo comando corre todos los tests de `tests/headless/`. Cada uno corre en su propio proceso, y un test nuevo entra solo:

```powershell
.\tools\test.ps1
```

Para correr solo algunos: `.\tools\test.ps1 -Solo physics`. Un test falla si sale con código distinto de 0
**o** si aparece un `SCRIPT ERROR`. `physics.gd` juega la mesa de verdad, con física real (unos 8 segundos):
sacar bola, flippers, lanzamiento, que la bola no atraviese paredes a velocidad máxima, bumpers, salvavidas,
drenaje y fin de partida. Los tests escriben en `user://test_*` y nunca tocan el récord real.

## Exportar a Android

El preset `Android` ya está en `export_presets.cfg` (arm64, inmersivo, permiso de vibración).
El SDK y la clave de debug se toman de la configuración del editor.

```powershell
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" build/pinball-debug.apk
```

```powershell
adb install -r build/pinball-debug.apk
```

O desde el editor, con el teléfono conectado por USB y la depuración activada: el ícono de Android arriba a la derecha (*Remote Debug*).

## Estructura

```
scenes/main.tscn            La mesa: paredes, flippers, bumpers... se editan en el editor
scripts/
  autoload/game_state.gd    Puntaje, bolas, récord, acciones de input por defecto
  main.gd                   Ciclo de la bola: sacar, drenar, salvavidas, popups
  table/                    Piezas reutilizables: ball, flipper, bumper, slingshot, wall, plunger
  ui/                       HUD (display 7 segmentos, vidas, pausa) y zonas táctiles
  fx/                       Efectos (números de puntaje)
tests/headless/             Tests automáticos (all.gd los encuentra y corre)
tools/test.ps1              Corre la suite
```

### Cómo está armada la física (para quien viene de Android)
- La **bola** es un `RigidBody2D` con detección continua de choques (CCD) y la física corre a
  **240 Hz**: así no atraviesa paredes ni a 4200 px/s.
- Los **flippers** son `AnimatableBody2D` (cinemáticos) que se giran a mano en cada paso de
  física. El motor deduce su velocidad del giro, y eso le da fuerza al golpe.
- **Bumpers y slingshots** implementan `on_ball_contact()`. La bola lo llama cuando empieza un
  contacto, y cada pieza decide la patada y los puntos.
- El **touch** y el teclado terminan en las mismas acciones (`flipper_left`, etc.), así que la
  mesa no sabe de dónde viene el input.
- Las paredes son `CollisionPolygon2D`: en el editor se mueven los puntos con el mouse.

## Hoja de ruta

0. ~~Godot + exportar APK~~
1. ~~Prototipo de física~~ ← *acá*. Falta: probar la sensación en un teléfono real y ajustar números.
2. HUD final, zonas seguras finas, vibración, menú de pausa completo.
3. Reglas (blancos abatibles, multiplicador, multibola, combos) y efectos visuales.
4. Sistema de skins (`TableTheme` como Resource) + primera skin completa: **Kernel Panic**.
5. Menú carrusel de mesas + top 10 de récords por mesa con iniciales.
6. Música: OST abierta con créditos, modo "mi música" y plugin Android en Kotlin.
7. Las otras 4 skins: 20.000 Leguas, Drácula, Baker Street, Alicia.
8. Modo de pruebas, idiomas es/en, CI y Play Store.
