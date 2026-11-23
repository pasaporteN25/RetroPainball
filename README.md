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

Skill shot: soltá el lanzador con la potencia dentro del marco dorado del resorte y mandá la bola al carril
SKILL SHOT del arco izquierdo para ganar 5.000. El kickback devuelve una vez por bola la bola que cae por el
outlane izquierdo. Llegar al multiplicador de bonus X5 da una bola extra (una por partida).

### Piezas genéricas: saucer y spinner (G-10)

Dos piezas sueltas y reutilizables para armar mesas nuevas (ninguna mesa actual las usa todavía). Son escenas
simples en `scenes/pieces/`; basta instanciarlas en el tablero y ajustarlas desde el inspector. Si no traen
`CollisionShape2D`, crean el suyo. Detectan solo la bola (capa de colisión 2) y solo suman puntos con la partida en curso.

- **Saucer / kicker** (`scenes/pieces/saucer.tscn`, `scripts/table/saucer.gd`): agujero que retiene la bola
  `saucer_hold_seconds`, suma `saucer_points` y la devuelve con velocidad `saucer_kick_speed` en `kick_direction`.
  Propiedades: `kick_direction`, `kick_speed` (0 = usa el valor de TableRules), `exit_offset`, `radius`,
  `rearm_distance`. Señal `kicked(ball)`. No recaptura la bola que acaba de expulsar.
- **Spinner** (`scenes/pieces/spinner.tscn`, `scripts/table/spinner.gd`): la bola lo atraviesa sin frenarse y lo hace
  girar a `velocidad × spinner_spin_per_speed` rad/s (más rápida la bola, más vueltas); el sentido depende de
  `lane_direction`. Cada vuelta completa suma `spinner_lap_points`. Propiedades: `length`, `friction`,
  `lane_direction`. Señal `lap_completed(total)`.

Los números viven en `TableRules` (grupo "Piezas genéricas"): `saucer_points`, `saucer_hold_seconds`,
`saucer_kick_speed`, `spinner_lap_points`, `spinner_spin_per_speed`. Los defaults no tocan las mesas actuales; una
mesa nueva los pisa en su `resources/rules/<id>.tres`. Suenan con `Sfx.play` y vibran como las demás piezas.
Test: `tests/headless/saucer_spinner.gd`.

## Correrlo

1. Abrí Godot 4.7.2 → *Importar* → elegí `project.godot`.
2. **F5** para abrir la pantalla de título (de ahí al selector de mesas). En la PC, el mouse simula el touch.
   En el selector, deslizá horizontalmente o usá las flechas del teclado, mando o pantalla para elegir una mesa; tocá la tarjeta central para jugar. Se muestra su récord y la marca **Continuar** si tiene una partida guardada.
   Para cambiar de mesa, elegí **Mesas** en la pausa o al terminar la partida.

El título tiene un cartel de neón vectorial, una bola con estela e insertos que se encienden
en secuencia con los colores de las mesas. Tocá el fondo o **Tocá para jugar** para pasar
al selector con un fundido breve. **Opciones** y **Récords** están debajo del botón principal.

En Linux también podés jugar desde la raíz del proyecto con `godot --path .`.

Cada mesa guarda automáticamente su partida en curso. Si volvés al selector o Android cierra el
juego, elegí la mesa marcada **Continuar**. Se recuperan el puntaje, las bolas en juego, el tiempo
del salvavidas y el progreso de 20.000 Leguas. La opción **Reiniciar** de la pausa empieza otra partida.

Cada mesa guarda su top 10 con tres iniciales estilo arcade. Al terminar la partida se ve el puntaje, el bonus
cobrado y el puesto logrado; si entra al top, se eligen las iniciales con las flechas (o el teclado) y se
elige **Otra partida** o **Mesas**. El botón **Récords** del selector abre la lista de cada mesa.

Cada mesa también lleva estadísticas (U-09): partidas jugadas, mejor bola (los puntos más altos de una sola bola) y
jackpots cobrados (20.000 Leguas, Drácula y Alicia). Se guardan en el mismo archivo de récords, en la sección
`stats/<mesa>` (`scripts/util/table_stats.gd`), se suman al terminar cada partida y se ven bajo el top 10 de la pantalla de récords.

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

## Modo de pruebas (solo desarrollo)

Se activa únicamente con el flag `--test-mode` en una build de debug (el editor o una exportación debug); sin el flag, o en una build release, no existe. En Linux:

```bash
godot --path . -- --test-mode
```

Abre la mesa (por el selector) y aparece un cartelito amarillo en el borde izquierdo, a media mesa, lejos del HUD y de las zonas táctiles.

| Tecla | Efecto |
|---|---|
| `F1` | Salta a la multibola de la mesa: Medianoche en Drácula, bolas del kraken en 20.000 Leguas. Kernel Panic aún no tiene multibola propia: suelta bolas hasta tener tres. |
| `F2` | Bola infinita: perder la última bola no gasta bolas ni cobra bonus, y sale otra. |
| `F3` | Muestra las colisiones (magenta sólidas, verde sensores). |
| `F4` | Velocidad del juego: 0.25x, 0.5x, 1x, 2x (cicla). Vuelve a 1x al salir de la mesa. |

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

## Licencias y créditos

Todo asset de terceros (música, fuentes, arte) se registra en `resources/credits.json`; el test `tests/headless/credits.gd` lo valida. Cada entrada lleva:

- `id` (único), `kind` (`music`, `font` o `art`), `title`, `author`, `license`, `source` (URL o procedencia) y, opcional, `path` (`res://...`; el test verifica que exista).
- `license` solo puede ser `CC0`, `CC-BY`, `CC-BY-SA`, `OFL`, `MIT`, `public-domain` u `original`. Nada NC ni ND.

Para M-03/M-05: agregar una entrada por pista o fuente antes de subir el archivo; el aviso "Sonando" y la pantalla de créditos pueden leer este mismo JSON.

## Estructura

```
scenes/title.tscn           Pantalla de título (escena inicial)
scenes/table_select.tscn    Selector de mesas
scenes/main.tscn            Mesa base y Kernel Panic
scenes/table_base.tscn      Geometría y controles compartidos
scenes/nautilus.tscn        20.000 Leguas, con geometría y misión propias
scripts/
  autoload/game_state.gd    Puntaje, bolas, récord, acciones de input por defecto
  autoload/sfx.gd           Efectos base generados en código (M-02)
  autoload/music.gd         Playlist por mesa con crossfade (M-04)
  main.gd                   Ciclo de la bola: sacar, drenar, salvavidas, popups
  table/                    Piezas reutilizables y arte del tablero (playfield_art.gd)
  ui/                       HUD (display 7 segmentos, vidas, pausa) y zonas táctiles
  fx/                       Indicadores de puntaje, ondas y chispas
tests/headless/             Tests automáticos (all.gd los encuentra y corre)
tools/test.ps1              Corre la suite
```

### Efectos de sonido (M-02)
No hay archivos de audio: `Sfx` (autoload) arma cada efecto como un `AudioStreamWAV` con PCM
generado (ondas y ruido con envolvente, estilo sfxr; originales, sin licencias) y lo reproduce
por el bus **Efectos**. Se usa con `Sfx.play(&"bumper")`. Sonidos: `flipper`, `bumper`,
`slingshot`, `plunger`, `drain`, `ball_saved`, `jackpot`. Se enganchan en las piezas de
`scripts/table` y en `main.gd`. En headless (sin dispositivo de audio) no tira errores.

### Música por mesa (M-04)
`Music` (autoload) reproduce la playlist de la mesa por el bus **Música**: orden aleatorio que no
repite el tema anterior seguido y crossfade (`crossfade_time`, 2 s) entre dos `AudioStreamPlayer`.
La lista sale del campo `playlist` de `TableTheme` (`PackedStringArray` de rutas `res://...`,
vacía por defecto = silencio, sin errores; también en headless sin dispositivo de audio).
`main.gd` llama a `Music.play_table(table_id)` al entrar a la mesa y a `Music.stop()` al salir.
API: `play_table(id)`, `play_list(items)` (streams, rutas o Dictionary con `stream`/`path`),
`next_track()`, `stop()`. La señal `track_changed(info)` trae `id`, `title`, `author`, `license`,
`source`, `path` e `index`; si la ruta está en `credits.json` se completan de ahí (M-05 mostrará
"Sonando: ..." con esto; la UI todavía no existe).

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
