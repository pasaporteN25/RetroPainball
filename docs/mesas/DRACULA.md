# Drácula (S-07)

Mesa temática basada en la novela *Drácula* (Bram Stoker, 1897, dominio público). Todo el arte y los
nombres son originales: **nada** de las películas (ni Universal, ni Hammer, ni Coppola), ni de la
imagen de Bela Lugosi. Reglas legales completas en `docs/ARTE.md` (S-04).

## Concepto
Transilvania de noche, tormenta, castillo en lo alto, murciélagos. El jugador reúne los murciélagos del
Conde, encierra bolas en los ataúdes y, cuando se cumplen dos encierros, llega la **MEDIANOCHE**
(multibola) donde el retrato del Conde paga el jackpot. Estética: gótica, fría; vectorial con brillo
(como Kernel Panic), no pintura.

- `table_id`: `"dracula"` · escena `scenes/dracula.tscn` (hereda de `scenes/table_base.tscn`).
- Paleta: noche `#0b0a14`, azul medianoche `#1b2140`, carmesí `#9e1b32`, hueso `#e9e1cf`, plata luna `#c9d3e6`,
  dorado viejo `#c9a35a`, niebla `#3a4468`. Acento del HUD/menús: carmesí.
- Título en la mesa: "DRÁCULA" y subtítulo "NOCHE EN TRANSILVANIA".

## Layout (coordenadas de `Table`; campo x 16..656, arco superior y≈126, flippers y=1250)
| Pieza | Nodo (hijo de `Table`) | Posición | Qué es |
|---|---|---|---|
| Luna y castillo | arte de fondo | luna (336,235), castillo en la parte alta | Solo arte; sin colisión |
| Banco de murciélagos | `Bats/BatLeft`, `BatMid`, `BatRight` | (205,430) (336,392) (467,430) | 3 blancos fijos (standup) con forma de murciélago |
| Candelabros | los 3 bumpers de la base: `BumperLeft/Right/Bottom` | (210,610) (462,610) (336,530) | Pop bumpers (puntaje 100) |
| Órbita Carfax | `Carfax/GateIn`, `Carfax/GateOut` + guía | entrada (590,470), salida (610,650) | Carril lateral derecho de dos compuertas (como la corriente del Nautilus pero a la derecha): cruzar entrada→salida en <3 s |
| Ataúd (lock) | `Coffin` | (150,790) | Plato que retiene la bola (ver reglas) |
| Retrato del Conde | `Portrait` | (336,830) | Blanco circular grande (r≈55); jackpot en Medianoche |

Debe quedar libre de piezas el pasillo central bajo el retrato hasta los flippers y la franja de las
lamparitas del multiplicador (336,1155) de `table_base.tscn`. Los flippers, gomas, carriles de retorno,
compuerta del carril de saque y lanzador vienen de la base y no se tocan.

## Reglas
1. **Murciélagos:** golpear los 3 blancos del banco los apaga/enciende (estado "activado"); al completar los 3:
   premio 1000, `GameState.raise_multiplier()`, se enciende **LOCK** y el banco se reinicia.
2. **Carfax:** cruzar GateIn y luego GateOut en menos de 3 s (o al revés no cuenta): +500 la primera vez, +1000
   la segunda, +1500 la tercera; la tercera además sube el multiplicador y reinicia la cuenta.
3. **Ataúd:** retiene la bola 0,6 s y la devuelve (+300). Con LOCK encendido, la bola queda **encerrada**
   (+ premio 500), el LOCK se apaga y sale una bola nueva al carril. Al tener **2 bolas encerradas**
   comienza **MEDIANOCHE**: se liberan las 2 bolas (multibola de 3 con la que está en juego).
4. **Medianoche:** mientras haya más de una bola, golpear el Retrato paga 5000 (jackpot); termina cuando
   queda una sola bola. Mensajes con `GameState.say(...)`: "LOCK ENCENDIDO", "BOLA ENCERRADA", "¡MEDIANOCHE!".
Todos los números y textos de estas reglas (1000, 500/1000/1500, 500, 300, 250, 5000, 0,6 s, 2 bolas, mensajes) salen de `resources/rules/dracula.tres` (`TableRules`, ver docs/ARTE.md); los de arriba son los valores por defecto.
5. Nada de esto se guarda en la partida (salvo las bolas vivas, como en las otras mesas). Las bolas
   encerradas cuentan como bolas en juego al guardar.

## Contrato entre lógica y arte
Nodo de reglas: `Table/DraculaRules` (script `scripts/table/dracula_rules.gd`, lo escribe lógica) con:
- Propiedades: `locks_lit: bool`, `locked_balls: int` (0..2), `midnight: bool`, `bats_hit: int` (0..3), `carfax_stage: int` (0..2).
- Señales: `bats_changed(hit: int)`, `lock_lit_changed(lit: bool)`, `ball_locked(count: int)`,
  `midnight_started`, `midnight_ended`, `carfax_scored(stage: int)`.
Arte: `scripts/table/dracula_art.gd` (lo escribe arte) con la misma API que los otros `*_art.gd`:
`pulse_score()`, `set_ball_save_fraction(fraction: float)` y `flash_jackpot()`. Busca
`get_node_or_null("../DraculaRules")` y conecta señales solo si existe (así funciona aunque las reglas
no estén todavía). Las piezas dibujan su propio estado en su `_draw()` (cada una con su script en `scripts/table/dracula_*.gd`).
La tarjeta del selector se dibuja en `scripts/ui/dracula_card.gd` (`static func draw(card: Control, rect: Rect2)`).

## Alta de la mesa (lista de control, la hace lógica)
`GameState.DRACULA := "dracula"` y su sección de récords; `game_save.gd` (`_valid_table` y el chequeo
de `sonar_mask`/`depth` en 0 también para Drácula); tarjeta nueva en `scripts/ui/table_select.gd`
(foco con teclado entre las 3 tarjetas, zoom/posición para 3); `scenes/dracula.tscn`; tests.
