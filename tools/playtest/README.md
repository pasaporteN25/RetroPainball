# Playtesting con bots (F1a)

Un bot juega partidas completas sin pantalla, mide todo y `report.gd` arma un informe. Los
**niveles** (`novato`, `medio`, `experto`, `azar`) son de habilidad del bot; el juego no tiene
dificultades.

```bash
./tools/playtest.sh -t kernel_panic -b medio -n 2000 -j 6      # corre y genera docs/playtest/<carpeta>.md
./tools/playtest.sh -t all -b all -n 200 -o build/playtest/antes   # todas las mesas y bots
godot --headless --path . -s tools/playtest/report.gd -- dir=build/playtest/despues base=build/playtest/antes
```

- `bot.gd`: el jugador (mira bolas con atraso, aprieta `flipper_left`/`flipper_right`/`launch`; el experto usa nudge).
- `session.gd`: una sesión (mesa + bot + semilla) y sus métricas; la comparten `run.gd` y el test.
- `run.gd`: un proceso = una combinación. Escribe `build/playtest/<fecha>/<mesa>_<bot>_s<n>.jsonl`.
- `report.gd`: junta los `.jsonl`, escribe el Markdown y un PNG de mapa de calor por mesa y bot.
- Test chico: `tests/headless/playtest_bot.gd` (experto vs. azar, 50 bolas, y misma semilla = mismo resultado).

Cada `.jsonl` tiene una línea `ball` por bola (puntos, segundos, por dónde se perdió, si había kickback),
una `game` por partida y un `summary` final (golpes por valor de puntaje, avisos del juego, TILT, bolas
salvadas/trabadas/rescatadas, máximo de bolas a la vez y la grilla del mapa de calor).

## ¿Acelerar el tiempo cambia la física? (verificado el 24/11/2026)

Sí, y por eso el runner no usa `Engine.time_scale` a secas. Medido con Kernel Panic, bot `medio`,
semilla 7, 12 bolas:

| Cómo se corre | Resultado |
|---|---|
| `time_scale = 4` solo (`naive=1`) | **Otra física.** Godot no sube los pasos de física por segundo: cada paso simula 4 veces más tiempo (4/240 s). Dio 4 bolas en 263 s con puntajes de ~220.000 por bola, contra ~9.000 a 1x. (Con x8 y pasos escalados vi avisos de bola fuera de la mesa, o sea tunneling; no lo medí en el naive.) |
| `time_scale = 4` y pasos x4 (`speed=4`) | Cada paso sigue siendo de 1/240 s, así que la física es la misma, pero **no es reproducible** con tiempo real: el saque (un `Timer`) y otros procesos dependen de cuántos cuadros hay entre paso y paso. Sin `--fixed-fps`, dos corridas iguales a 1x tampoco coinciden entre sí. Estadísticamente parecido, bola por bola no. |
| `--fixed-fps 60` a 1x (**lo que usa `playtest.sh`**) | **Determinista**: dos corridas con la misma semilla dieron las 12 bolas idénticas (puntaje y segundos). Y va ~25 veces más rápido que el tiempo real (CPU, sin esperar los cuadros). |

Conclusión: se corre con `--fixed-fps 60` y velocidad 1 (cada cuadro son exactamente 4 pasos de 1/240 s).
Subir la velocidad (`-x`) casi no suma porque el límite ya es la CPU, y cambia la secuencia de cuadros.
`speed=4` con `--fixed-fps 240` tampoco repitió exactamente la corrida de `--fixed-fps 60`: si hace falta
comparar corridas, hacerlo siempre con el mismo `-x`.

Cada proceso de Godot ocupa varios hilos (sys alto); usá `-j` de la mitad de los núcleos (el valor por defecto).

## Cosas que el bot ya encontró (para F1c)

- **Bola salvada sin límite**: `main.gd` vuelve a armar `_save_armed` en cada `serve_ball()`, incluido el
  saque que viene de una bola salvada. Si la bola se pierde antes de 8 s de lanzada, se salva de nuevo,
  una y otra vez (el bot al azar tuvo 3,5 salvadas por bola perdida). No se tocó: es de F1c/Lucas decidir
  si es intencional.
- El bot **no lee las reglas de cada mesa** (no apunta a lo que está encendido); medio y experto se
  diferencian en reacción, puntería del golpe, retención y nudge. Es una limitación de F1a.
- El mapa de calor es solo la grilla de la bola (sin dibujar la mesa de fondo, que no se renderiza en headless).
