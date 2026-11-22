# Alicia (S-09)

Mesa temática basada en *Alicia en el país de las maravillas* (Lewis Carroll, 1865, dominio público) y en el estilo de los grabados de John Tenniel (también dominio público). Todo el arte y los nombres son originales: **nada** de la película de Disney (ni el vestido azul con diadema negra, ni la paleta, ni el diseño del gato o del conejo de esa versión), ni de ninguna otra adaptación. Se dibuja en vectorial con trazo de grabado (línea fina, rayado cruzado) y brillo suave, no se copian los grabados de Tenniel. Reglas legales completas en `docs/ARTE.md` (S-04).

## Concepto
Alicia baja por la madriguera y el tamaño pasa a ser parte del juego. Esta es la mesa **más compleja** hasta ahora (decisión de proyecto: la complejidad crece mesa a mesa). Respecto de Drácula suma un **estado persistente que cambia las reglas** (tamaño), un blanco que **aparece y desaparece solo** (el gato) y una multibola que se gana por una vía distinta.

- `table_id`: `"alicia"` · escena `scenes/alicia.tscn` (hereda de `scenes/table_base.tscn`).
- Paleta: tinta `#14110f`, jardín nocturno `#12201f`, papel `#ece2c8`, sepia `#6b5436`, rojo Reina `#b3262e`, verde té `#2f7f86`, oro `#c9a24a`, lila `#7a5fa8`. Acento del HUD/menús: rojo Reina.
- Título en la mesa: "ALICIA" y subtítulo "EN EL PAÍS DE LAS MARAVILLAS".

## Layout (coordenadas de `Table`; campo x 16..656, arco superior y≈126, flippers y=1250)
Las coordenadas son una propuesta: ajustar al medir la física, sin tapar el pasillo central bajo la Tetera ni la franja de las lamparitas (336,1155).

| Pieza | Nodo (hijo de `Table`) | Posición | Qué es |
|---|---|---|---|
| Madriguera | `Rabbithole` | (336,300) | Plato que retiene la bola (como el ataúd de Drácula) |
| Banco de naipes | `Cards/Card0..Card3` | (200,440) (290,410) (382,410) (472,440) | 4 blancos fijos con forma de naipe (♠ ♥ ♦ ♣) |
| BEBÉ-ME | `Size/DrinkMe` | (46,760) | Blanco en la pared izquierda: achica |
| CÓMEME | `Size/EatMe` | (626,760) | Blanco en la pared derecha: agranda |
| Gato de Cheshire | `Cheshire` | (545,330) | Blanco circular (la sonrisa) que aparece y desaparece |
| Hongos | `BumperLeft/Right/Bottom` | (210,610) (462,610) (336,530) | Los 3 bumpers de la base, con forma de hongo (puntaje 100) |
| Tetera | `Teapot` | (336,830) | Blanco circular grande (r≈55); jackpot en Té Loco |

Los flippers, gomas, carriles de retorno, compuerta del carril de saque, lanzador, skill shot y kickback vienen de la base y no se tocan.

## Reglas
1. **Tamaño:** el estado vale `NORMAL`, `CHICA` o `GRANDE`. Golpear BEBÉ-ME pasa a `CHICA`; golpear CÓMEME pasa a `GRANDE`; golpear el que ya está activo vuelve a `NORMAL`. Cada cambio paga 100 y avisa con `GameState.say("CHICA")` / `"GRANDE"` / `"TAMAÑO NORMAL"`. El estado se pierde al perder la bola.
2. **Naipes:** golpear cada naipe lo "da vuelta" (se enciende). Si el tamaño es `GRANDE`, cada golpe vale doble (paga 2x el puntaje del golpe) y da vuelta el naipe vecino que siga apagado. Al darlos vuelta los 4: premio 1000, `GameState.raise_multiplier()` y el banco se reinicia.
3. **Madriguera:** retiene la bola 1 s y la devuelve (+300). Si el tamaño es `CHICA` y hay LOCK encendido, la bola queda **encerrada** (+ premio 500), el LOCK se apaga y sale una bola nueva al carril. El LOCK se enciende al completar el banco de naipes (regla 2). Con tamaño distinto de `CHICA` la madriguera solo retiene y devuelve.
4. **Gato de Cheshire:** ciclo automático de 7 s: **visible 4 s** (golpeable) y **invisible 3 s** (la bola lo atraviesa). Golpearlo visible paga 1500 y lo mantiene visible 4 s más (una vez por ciclo). Durante Té Loco queda siempre visible.
5. **Té Loco:** con **2 bolas encerradas** comienza **TÉ LOCO** (multibola de 3: se liberan las 2 bolas más la que está en juego). Mientras haya más de una bola, golpear la Tetera paga 5000 (jackpot) y el reloj de bonus queda detenido (no baja el bonus). Termina cuando queda una sola bola. Mensajes: "NAIPES COMPLETOS", "LOCK ENCENDIDO", "BOLA ENCERRADA", "¡TÉ LOCO!".
6. Los puntajes, umbrales, tiempos y mensajes **no van cableados**: viven en `TableRules` (grupo nuevo `Alicia`) y en sus `RuleStage` donde haya etapas. Lo que no se guarda en la partida: el estado de tamaño, los naipes y el ciclo del gato. Las bolas encerradas cuentan como bolas en juego al guardar (igual que en Drácula).

## Contrato entre lógica y arte
Nodo de reglas: `Table/AliceRules` (script `scripts/table/alice_rules.gd`, lo escribe lógica) con:
- Propiedades: `size_state: int` (0 normal, 1 chica, 2 grande), `cards_mask: int` (0..15, un bit por naipe), `lock_lit: bool`, `locked_balls: int` (0..2), `tea_party: bool`, `cheshire_visible: bool`.
- Señales: `size_changed(state: int)`, `card_flipped(index: int, mask: int)`, `cards_completed`, `lock_lit_changed(lit: bool)`, `ball_locked(count: int)`, `cheshire_changed(visible: bool)`, `cheshire_hit`, `tea_party_started`, `tea_party_ended`.
Arte: `scripts/table/alice_art.gd` (lo escribe arte) con la misma API que los otros `*_art.gd`: `pulse_score()`, `set_ball_save_fraction(fraction: float)` y `flash_jackpot()`. Busca `get_node_or_null("../AliceRules")` y conecta señales solo si existe. Las piezas dibujan su propio estado en su `_draw()` (cada una con su script en `scripts/table/alice_*.gd`). El dibujo de cada pieza vive en `scripts/table/alice_visuals.gd` (`class_name AliceVisuals`, funciones estáticas `draw_card`, `draw_size_target`, `draw_cheshire`, `draw_mushroom`, `draw_teapot`, `draw_rabbithole`): lo escribe arte y lo llaman las piezas de lógica desde su `_draw()`; las firmas no cambian. La tarjeta del selector se dibuja en `scripts/ui/alice_card.gd` (`static func draw(card: Control, rect: Rect2)`).

Arte a resolver: el cambio de tamaño debe leerse a primera vista (por ejemplo, marco o viñeta del playfield que cambia de color y grosor, y los hongos que se ven más grandes o chicos solo como dibujo; **la física no cambia de tamaño**). El gato desaparece dejando solo la sonrisa y se desvanece sin parpadeos rápidos. Mantener lo ya acordado en rendimiento móvil: pocas capas y redibujado limitado.

## Alta de la mesa (lista de control, la hace lógica)
- `GameState.ALICIA := "alicia"` y su sección de récords; `game_save.gd` (`_valid_table` y el estado a guardar, que es el mínimo de la regla 6).
- `resources/themes/alicia.tres` (`TableTheme`), `resources/rules/alicia.tres` (`TableRules`, grupo `Alicia`), sumar el id a `TABLE_IDS` de `scripts/ui/records_screen.gd`.
- Tarjeta nueva en `scripts/ui/table_select.gd` (el selector pasa de 3 a 4 tarjetas: foco con teclado, zoom y posición para 4).
- `scenes/alicia.tscn`.
- Vibración siempre con `Settings.vibrate(...)`, nunca `Input.vibrate_handheld` directo (lo valida `tests/headless/vibrate_calls.gd`).
- Tests: `alice_rules`, `art_alicia`, `alicia_resume`, y que `table_random` (Q-04) y `table_rules` cubran la mesa nueva.
