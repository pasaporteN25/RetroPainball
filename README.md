# Pinball Temático

Pinball para Android (vertical, a pantalla casi completa) con mesas temáticas.
Motor: **Godot 4.7.2** (GDScript), renderer *Compatibility* para cubrir la mayor cantidad de teléfonos.

Hay dos mesas, cada una con tres bolas, salvavidas y su propio récord local.

- **Kernel Panic** es el pinball clásico. Tiene tres carriles de puntaje (BOOT, BUS A y BUS B),
  dos blancos IRQ y bumpers sobre un circuito impreso.
- **20.000 Leguas bajo el mar** suma una órbita de babor, una cámara que atrapa y devuelve la bola
  hacia estribor, tres sonares y un kraken giratorio. Pasá la bola
  sobre los tres sonares y golpeá al kraken para ganar 5.000 puntos y descender 1.500 m. Si hay
  una sola bola, el golpe también activa la multibola. Los sonares y la profundidad se mantienen
  al perder una bola.

En ambas mesas, los retornos interiores llevan a los flippers y suman 50 puntos. Las salidas
exteriores llevan al drenaje. La compuerta superior desvía hacia el tablero las bolas que vuelven
al carril de lanzamiento.

## Correrlo

1. Abrí Godot 4.7.2 → *Importar* → elegí `project.godot`.
2. **F5** para abrir el selector de mesas. En la PC, el mouse simula el touch.
   Para cambiar de mesa, elegí **Mesas** en la pausa o al terminar la partida.

En Linux también podés jugar desde la raíz del proyecto con `godot --path .`.

Cada mesa guarda automáticamente su partida en curso. Si volvés al selector o Android cierra el
juego, elegí la mesa marcada **Continuar**. Se recuperan el puntaje, las bolas en juego, el tiempo
del salvavidas y el progreso de 20.000 Leguas. La opción **Reiniciar** de la pausa empieza otra partida.

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
`nautilus.gd` verifica los sensores, el jackpot, la multibola, el progreso y los récords por mesa.

En Linux, corré la misma suite con `godot --headless --path . -s tests/headless/all.gd`.

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
scenes/table_select.tscn    Selector de mesas
scenes/main.tscn            Mesa base y Kernel Panic
scenes/table_base.tscn      Geometría y controles compartidos
scenes/nautilus.tscn        20.000 Leguas, con geometría y misión propias
scripts/
  autoload/game_state.gd    Puntaje, bolas, récord, acciones de input por defecto
  main.gd                   Ciclo de la bola: sacar, drenar, salvavidas, popups
  table/                    Piezas reutilizables y arte del tablero (playfield_art.gd)
  ui/                       HUD (display 7 segmentos, vidas, pausa) y zonas táctiles
  fx/                       Indicadores de puntaje, ondas y chispas
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

El detalle de cada tarea, por categoría (gameplay, mesas y skins, arte, audio, menú, Android,
calidad), está en [docs/BACKLOG.md](docs/BACKLOG.md).

0. ~~Godot + exportar APK~~
1. ~~Prototipo de física~~ ← *acá*. Falta: probar la sensación en un teléfono real y ajustar números.
2. HUD final, zonas seguras finas, vibración, menú de pausa completo.
3. Reglas (blancos abatibles, multiplicador, multibola, combos) y efectos visuales.
4. Sistema de skins (`TableTheme` como Resource) + primera skin completa: **Kernel Panic**.
5. Menú carrusel de mesas + top 10 de récords por mesa con iniciales.
6. Música: OST abierta con créditos, modo "mi música" y plugin Android en Kotlin.
7. Las otras 4 skins: 20.000 Leguas, Drácula, Baker Street, Alicia.
8. Modo de pruebas, idiomas es/en, CI y Play Store.
