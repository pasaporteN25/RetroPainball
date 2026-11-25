# Informe de playtesting bot_aim

Generado con `tools/playtest/report.gd` a partir de `bot_aim`. Los niveles son de **habilidad del bot**, no de dificultad del juego.

## Qué cambió y qué se midió (lectura a mano)

Esta corrida (300 bolas por mesa y bot, semilla 1, `./tools/playtest.sh -t all -b all -n 300 -j 12`) usa el bot
nuevo de `tools/playtest/bot.gd` + `aim.gd`. La anterior es `skill2000.md` (2.000 bolas, bot viejo). Las mesas, las
reglas y la física **no cambiaron**: la diferencia es solo del bot.

Qué hace distinto el bot: predice con gravedad dónde y cuándo toca cada paleta (antes disparaba por altura fija y
llegaba tarde a las bolas rápidas), lee las reglas de cada mesa (`aim.gd`: blancos y rollovers apagados, `fork`/`sudo`
en Kernel Panic, sonares y kraken, murciélagos, ataúd y retrato, naipes, madriguera y tetera) y elige en qué punto de
la paleta pegarle a una bola lenta usando una calibración medida del ángulo de salida; y atrapa con criterio
(solo bolas de menos de 450 px/s: atrapar las rápidas empeoraba todo, rebotan por encima de la punta). El experto,
además, empuja (nudge) antes y con enfriamiento de 1,4 s sin llegar a TILT.

### Contra las metas del plan (F1c), por mesa

| Métrica | Meta | Kernel Panic | Nautilus | Drácula | Alicia | Antes (skill2000) |
|---|---|---|---|---|---|---|
| Segundos por bola, medio | 45 a 90 | 33,9 | 29,7 | 44,3 | 40,8 | 11,3 / 13,9 / 10,7 / 12,0 |
| Bolas perdidas por outlanes, medio | 35 a 50 % | 70 % | 36 % | 38 % | 44 % | 0 a 8 % por afuera (92 a 100 % por el centro) |
| Puntaje experto / novato | 4x a 10x | 9,8x | 10,9x | 9,3x | 9,1x | 4,9x / 5,0x / 5,6x / 4,5x |
| Segundos por bola, experto | (sin meta) | 53,8 | 70,3 | 78,1 | 59,5 | 26,7 / 27,9 / 35,2 / 32,1 |
| Segundos por bola, novato | (sin meta) | 10,7 | 10,7 | 10,7 | 10,8 | 10,7 / 10,9 / 10,9 / 10,8 |

Resumen honesto:

- **Cumplida**: puntaje experto / novato entre 4x y 10x en tres mesas (Nautilus queda en 10,9x, apenas pasada);
  el centro dejó de ser la pérdida casi única (el experto pierde por el centro solo 17 a 31 % de las bolas y el
  medio 31 a 64 %, contra 92 a 100 % antes), y el porcentaje de outlanes del medio entra en 35 a 50 % en Nautilus,
  Drácula y Alicia (36, 38 y 44 %).
- **Casi**: segundos por bola del medio en Drácula (44,3) y Alicia (40,8) están a un paso del piso de 45 s.
- **No cumplida**: Kernel Panic y Nautilus del medio quedan en 34 y 30 s, y en Kernel Panic el 70 % se pierde por
  outlanes (el experto, 84 %). Ni el bot "ideal" (reacción de 30 ms, sin error de timing) pasó de unos 45 a 55 s por
  bola en Kernel Panic: ahí el techo lo pone la mesa, no el bot. Las trazas de las bolas perdidas por outlane muestran
  que bajan pegadas a la pared derecha (x ~ 625 a 640) desde mucho más arriba que los flippers, a 700 a 1.000 px/s,
  así que ninguna paleta llega. Con una mesa así, subir la habilidad solo cambia el centro por outlane. Eso es
  para F1c (outlane derecho de Kernel Panic, que además no tiene kickback), no para el bot.
- **No cumplida**: la diferencia entre outlane izquierdo y derecho (menos de 10 puntos): en Kernel Panic el medio
  pierde 22 % por la izquierda y 48 % por la derecha, y en el resto la derecha también pesa más. Tampoco la tocó el bot.
- **No medida acá**: partidas que llegan a multibola o jackpot y "ninguna pieza paga más del 35 %" (los números están
  en las secciones de cada mesa, pero con 300 bolas son pocos para sacar conclusiones; pide la corrida de 2.000).

Cómo se calibró (corridas de 40 a 100 bolas, un proceso por configuración, Kernel Panic salvo aclaración):

| Configuración | Segundos por bola | Outlanes |
|---|---|---|
| Experto del bot viejo, con atrape de cualquier bola | 14,6 | 30 % |
| Mismo, sin atrapar | 37,6 | 72 % |
| Mismo, atrapando solo bolas de menos de 450 px/s | 42,7 | 85 % |
| Experto final (reacción 50 ms, lead 1,0, timing 6 ms, nudge cada 1,4 s) | 55,2 | 85 % |
| Medio, reacción 110 ms y lead 0,6 (perfil viejo con el bot nuevo) | 20,6 | 22 % |
| Medio final (reacción 80 ms, lead 0,9, timing 12 ms, atrape 50 %), 4 mesas, 100 bolas | 37,6 / 44,5 / 32,8 / 31,9 | 40 / 39 / 73 / 34 % |

Qué quedó afinado: `novato` (reacción 180 ms, sin anticipar, sin apuntar ni atrapar) casi no cambió y sigue en ~10,7 s
por bola; `medio` y `experto` en `PROFILES` de `bot.gd`. Con `PLAYTEST_TUNE='{"lead":0.9}'` se pisan parámetros sin
editar el código.

Limitaciones del bot: la predicción es balística (ignora rebotes), el apuntado ignora paredes, bumpers y gravedad
sobre el tiro (solo el ángulo de salida calibrado con la paleta izquierda en reposo, espejado para la derecha), y
no hay ninguna lógica de "rampa"/órbita para las piezas que cuentan solo de arriba hacia abajo (Carfax).

## Resumen

| Mesa / bot | Bolas | Partidas | Puntos por bola (media / mediana / p90) | Puntos por partida (media / mediana / máx) | Segundos por bola (media) |
|---|---:|---:|---|---|---:|
| alicia/azar | 300 | 100 | 1885 / 990 / 5280 | 6483 / 5578 / 18998 | 13.4 |
| alicia/experto | 300 | 86 | 20157 / 13430 / 39920 | 96229 / 71800 / 327869 | 59.5 |
| alicia/medio | 300 | 90 | 12472 / 8100 / 26110 | 54894 / 36828 / 254984 | 40.8 |
| alicia/novato | 300 | 99 | 2218 / 2000 / 4200 | 7585 / 6985 / 28060 | 10.8 |
| dracula/azar | 300 | 100 | 1070 / 900 / 2350 | 3538 / 3707 / 10604 | 13.1 |
| dracula/experto | 300 | 99 | 15068 / 8800 / 25710 | 53722 / 38225 / 392929 | 78.1 |
| dracula/medio | 300 | 99 | 9680 / 6520 / 17210 | 34021 / 25509 / 310632 | 44.3 |
| dracula/novato | 300 | 100 | 1616 / 2000 / 3800 | 5334 / 5126 / 10681 | 10.7 |
| kernel_panic/azar | 300 | 99 | 1394 / 830 / 3440 | 5178 / 4627 / 24956 | 12.9 |
| kernel_panic/experto | 300 | 76 | 16486 / 11900 / 34595 | 94011 / 96504 / 255770 | 53.8 |
| kernel_panic/medio | 300 | 83 | 9799 / 6905 / 21035 | 49773 / 46599 / 131285 | 33.9 |
| kernel_panic/novato | 300 | 100 | 1689 / 2000 / 3680 | 5718 / 5477 / 13741 | 10.7 |
| nautilus/azar | 300 | 99 | 2463 / 1240 / 7620 | 8755 / 4862 / 43881 | 13.4 |
| nautilus/experto | 300 | 87 | 25108 / 18710 / 53500 | 119237 / 93908 / 458954 | 70.3 |
| nautilus/medio | 300 | 96 | 10894 / 6040 / 26630 | 42960 / 32269 / 245336 | 29.7 |
| nautilus/novato | 300 | 100 | 2297 / 2410 / 4720 | 7653 / 6875 / 18064 | 10.7 |

## alicia/azar

- Bolas: 300 en 100 partidas (1 proceso(s), velocidad x1.0, 4019 s de juego en 397 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 96%, outlane_der 4%.
- Se perdió con kickback listo: 92% de las bolas.
- Bolas salvadas: 240, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 150 | 817 | 21.7% |
| 250 | 428 | 18.9% |
| 1500 | 62 | 16.4% |
| 100 | 884 | 15.6% |
| 300 | 216 | 11.5% |
| 1000 | 52 | 9.2% |
| 2000 | 13 | 4.6% |
| 50 | 119 | 1.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.80 por bola
- `SKILL SHOT: AL CARRIL`: 0.66 por bola
- `BONUS ### X#`: 0.50 por bola
- `GRANDE`: 0.44 por bola
- `BOLA #`: 0.40 por bola
- `BONUS ## X#`: 0.37 por bola
- `CHICA`: 0.22 por bola
- `NAIPES COMPLETOS`: 0.17 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `¡KICKBACK!`: 0.08 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/azar](bot_aim/heat_alicia_azar.png)

## alicia/experto

- Bolas: 300 en 86 partidas (1 proceso(s), velocidad x1.0, 17859 s de juego en 1328 s reales).
- Por dónde se pierde: outlane_izq 12%, centro 31%, outlane_der 57%.
- Se perdió con kickback listo: 55% de las bolas.
- Bolas salvadas: 44, TILT: 0, bolas trabadas: 4, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 4288 | 17.7% |
| 1500 | 646 | 16.0% |
| 2000 | 428 | 14.2% |
| 300 | 2269 | 11.3% |
| 1000 | 617 | 10.2% |
| 5000 | 123 | 10.2% |
| 100 | 5926 | 9.8% |
| 150 | 3225 | 8.0% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `NAIPES COMPLETOS`: 2.06 por bola
- `GRANDE`: 1.85 por bola
- `CHICA`: 1.60 por bola
- `SKILL SHOT: AL CARRIL`: 1.43 por bola
- `SKILL SHOT ####`: 1.43 por bola
- `TAMAÑO NORMAL`: 0.75 por bola
- `BONUS #### X#`: 0.61 por bola
- `LOCK ENCENDIDO`: 0.53 por bola
- `¡KICKBACK!`: 0.45 por bola
- `¡JACKPOT!  ####`: 0.41 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/experto](bot_aim/heat_alicia_experto.png)

## alicia/medio

- Bolas: 300 en 90 partidas (3 proceso(s), velocidad x1.0, 12231 s de juego en 1271 s reales).
- Por dónde se pierde: outlane_izq 13%, centro 56%, outlane_der 31%.
- Se perdió con kickback listo: 60% de las bolas.
- Bolas salvadas: 81, TILT: 0, bolas trabadas: 2, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 3250 | 21.7% |
| 2000 | 302 | 16.1% |
| 1500 | 367 | 14.7% |
| 300 | 1415 | 11.3% |
| 100 | 4000 | 10.7% |
| 1000 | 382 | 10.2% |
| 150 | 2119 | 8.5% |
| 5000 | 29 | 3.9% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `GRANDE`: 1.31 por bola
- `NAIPES COMPLETOS`: 1.27 por bola
- `CHICA`: 1.16 por bola
- `SKILL SHOT: AL CARRIL`: 1.01 por bola
- `SKILL SHOT ####`: 1.01 por bola
- `TAMAÑO NORMAL`: 0.62 por bola
- `BONUS ### X#`: 0.59 por bola
- `LOCK ENCENDIDO`: 0.40 por bola
- `¡KICKBACK!`: 0.40 por bola
- `BONUS #### X#`: 0.40 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/medio](bot_aim/heat_alicia_medio.png)

## alicia/novato

- Bolas: 300 en 99 partidas (1 proceso(s), velocidad x1.0, 3228 s de juego en 360 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 292, TILT: 0, bolas trabadas: 3, rescates por escape: 0, máximo de bolas a la vez: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 170 | 51.1% |
| 150 | 657 | 14.8% |
| 1500 | 56 | 12.6% |
| 100 | 476 | 7.2% |
| 1000 | 42 | 6.3% |
| 300 | 108 | 4.9% |
| 250 | 65 | 2.4% |
| 50 | 66 | 0.5% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.97 por bola
- `BONUS ### X#`: 0.68 por bola
- `SKILL SHOT ####`: 0.57 por bola
- `SKILL SHOT: AL CARRIL`: 0.57 por bola
- `BOLA #`: 0.41 por bola
- `GRANDE`: 0.29 por bola
- `BONUS ## X#`: 0.18 por bola
- `NAIPES COMPLETOS`: 0.14 por bola
- `LOCK ENCENDIDO`: 0.12 por bola
- `CHICA`: 0.11 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/novato](bot_aim/heat_alicia_novato.png)

## dracula/azar

- Bolas: 300 en 100 partidas (1 proceso(s), velocidad x1.0, 3918 s de juego en 436 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 98%, outlane_der 2%.
- Se perdió con kickback listo: 94% de las bolas.
- Bolas salvadas: 218, TILT: 0, bolas trabadas: 4, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 619 | 48.2% |
| 100 | 579 | 18.0% |
| 300 | 152 | 14.2% |
| 150 | 120 | 5.6% |
| 2000 | 8 | 5.0% |
| 50 | 252 | 3.9% |
| 500 | 14 | 2.2% |
| 10 | 523 | 1.6% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.73 por bola
- `SKILL SHOT: AL CARRIL`: 0.55 por bola
- `BONUS ### X#`: 0.46 por bola
- `BOLA #`: 0.43 por bola
- `BONUS ## X#`: 0.35 por bola
- `¡KICKBACK!`: 0.06 por bola
- `CARFAX #/#`: 0.05 por bola
- `BONUS # X#`: 0.05 por bola
- `SKILL SHOT ####`: 0.03 por bola
- `BOLA DESTRABADA`: 0.01 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/azar](bot_aim/heat_dracula_azar.png)

## dracula/experto

- Bolas: 300 en 99 partidas (1 proceso(s), velocidad x1.0, 23420 s de juego en 1996 s reales).
- Por dónde se pierde: outlane_izq 14%, centro 26%, outlane_der 60%.
- Se perdió con kickback listo: 63% de las bolas.
- Bolas salvadas: 35, TILT: 0, bolas trabadas: 15, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 6818 | 37.7% |
| 2000 | 403 | 17.8% |
| 5000 | 122 | 13.5% |
| 100 | 4568 | 10.1% |
| 300 | 1391 | 9.2% |
| 150 | 959 | 3.2% |
| 50 | 2432 | 2.7% |
| 1000 | 94 | 2.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.34 por bola
- `SKILL SHOT: AL CARRIL`: 1.34 por bola
- `BONUS ### X#`: 0.54 por bola
- `BONUS #### X#`: 0.45 por bola
- `¡JACKPOT!  ####`: 0.41 por bola
- `¡KICKBACK!`: 0.37 por bola
- `BOLA #`: 0.33 por bola
- `CARFAX #/#`: 0.26 por bola
- `LOCK ENCENDIDO`: 0.24 por bola
- `BOLA ENCERRADA`: 0.20 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/experto](bot_aim/heat_dracula_experto.png)

## dracula/medio

- Bolas: 300 en 99 partidas (3 proceso(s), velocidad x1.0, 13292 s de juego en 1456 s reales).
- Por dónde se pierde: outlane_izq 8%, centro 62%, outlane_der 30%.
- Se perdió con kickback listo: 65% de las bolas.
- Bolas salvadas: 67, TILT: 0, bolas trabadas: 7, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 4054 | 34.9% |
| 2000 | 285 | 19.6% |
| 5000 | 66 | 11.4% |
| 300 | 1027 | 10.6% |
| 100 | 3066 | 10.6% |
| 150 | 706 | 3.6% |
| 50 | 1695 | 2.9% |
| 1000 | 80 | 2.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 0.95 por bola
- `SKILL SHOT: AL CARRIL`: 0.95 por bola
- `BONUS ### X#`: 0.73 por bola
- `¡KICKBACK!`: 0.35 por bola
- `BOLA #`: 0.33 por bola
- `BONUS #### X#`: 0.25 por bola
- `CARFAX #/#`: 0.25 por bola
- `¡BOLA SALVADA!`: 0.22 por bola
- `¡JACKPOT!  ####`: 0.22 por bola
- `LOCK ENCENDIDO`: 0.18 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/medio](bot_aim/heat_dracula_medio.png)

## dracula/novato

- Bolas: 300 en 100 partidas (1 proceso(s), velocidad x1.0, 3198 s de juego en 401 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 100%, outlane_der 0%.
- Se perdió con kickback listo: 99% de las bolas.
- Bolas salvadas: 291, TILT: 0, bolas trabadas: 7, rescates por escape: 0, máximo de bolas a la vez: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 176 | 72.6% |
| 250 | 177 | 9.1% |
| 100 | 301 | 6.2% |
| 500 | 34 | 3.5% |
| 150 | 112 | 3.5% |
| 300 | 50 | 3.1% |
| 50 | 113 | 1.2% |
| 1000 | 3 | 0.6% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.97 por bola
- `BONUS ### X#`: 0.61 por bola
- `SKILL SHOT ####`: 0.59 por bola
- `SKILL SHOT: AL CARRIL`: 0.59 por bola
- `BOLA #`: 0.41 por bola
- `BONUS ## X#`: 0.23 por bola
- `CARFAX #/#`: 0.12 por bola
- `BONUS # X#`: 0.05 por bola
- `BOLA DESTRABADA`: 0.02 por bola
- `¡KICKBACK!`: 0.01 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/novato](bot_aim/heat_dracula_novato.png)

## kernel_panic/azar

- Bolas: 300 en 99 partidas (1 proceso(s), velocidad x1.0, 3881 s de juego en 360 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 91%, outlane_der 8%.
- Se perdió con kickback listo: 88% de las bolas.
- Bolas salvadas: 233, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 1000 | 84 | 20.1% |
| 1500 | 55 | 19.7% |
| 100 | 770 | 18.4% |
| 225 | 269 | 14.5% |
| 160 | 210 | 8.0% |
| 500 | 62 | 7.4% |
| 140 | 106 | 3.5% |
| 25 | 487 | 2.9% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.78 por bola
- `SKILL SHOT: AL CARRIL`: 0.56 por bola
- `BONUS X#`: 0.46 por bola
- `BONUS ### X#`: 0.46 por bola
- `BOLA #`: 0.39 por bola
- `BONUS ## X#`: 0.33 por bola
- `PROCESO #/#`: 0.26 por bola
- `FORK() LISTO: AL SAUCER`: 0.14 por bola
- `¡KICKBACK!`: 0.12 por bola
- `BONUS # X#`: 0.10 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/azar](bot_aim/heat_kernel_panic_azar.png)

## kernel_panic/experto

- Bolas: 300 en 76 partidas (1 proceso(s), velocidad x1.0, 16141 s de juego en 1505 s reales).
- Por dónde se pierde: outlane_izq 28%, centro 17%, outlane_der 56%.
- Se perdió con kickback listo: 40% de las bolas.
- Bolas salvadas: 42, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 1000 | 1090 | 22.0% |
| 100 | 8120 | 16.4% |
| 225 | 3148 | 14.3% |
| 2000 | 342 | 13.8% |
| 1500 | 425 | 12.9% |
| 500 | 669 | 6.8% |
| 160 | 1904 | 6.2% |
| 140 | 710 | 2.0% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `BONUS X#`: 2.68 por bola
- `SKILL SHOT ####`: 1.14 por bola
- `SKILL SHOT: AL CARRIL`: 1.14 por bola
- `PROCESO #/#`: 0.72 por bola
- `FORK() LISTO: AL SAUCER`: 0.66 por bola
- `¡KICKBACK!`: 0.60 por bola
- `BONUS #### X#`: 0.54 por bola
- `SEGFAULT: FIN DE LA MULTIBOLA`: 0.54 por bola
- `¡FORK()!  MULTIBOLA`: 0.54 por bola
- `BONUS ### X#`: 0.46 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/experto](bot_aim/heat_kernel_panic_experto.png)

## kernel_panic/medio

- Bolas: 300 en 83 partidas (3 proceso(s), velocidad x1.0, 10174 s de juego en 1159 s reales).
- Por dónde se pierde: outlane_izq 22%, centro 31%, outlane_der 48%.
- Se perdió con kickback listo: 44% de las bolas.
- Bolas salvadas: 93, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 1000 | 649 | 22.1% |
| 2000 | 268 | 18.2% |
| 100 | 4657 | 15.8% |
| 225 | 1918 | 14.7% |
| 1500 | 236 | 12.0% |
| 500 | 358 | 6.1% |
| 160 | 995 | 5.4% |
| 140 | 395 | 1.9% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `BONUS X#`: 2.11 por bola
- `SKILL SHOT ####`: 0.89 por bola
- `SKILL SHOT: AL CARRIL`: 0.89 por bola
- `BONUS ### X#`: 0.66 por bola
- `PROCESO #/#`: 0.56 por bola
- `¡KICKBACK!`: 0.56 por bola
- `FORK() LISTO: AL SAUCER`: 0.51 por bola
- `SEGFAULT: FIN DE LA MULTIBOLA`: 0.34 por bola
- `¡FORK()!  MULTIBOLA`: 0.34 por bola
- `BONUS #### X#`: 0.31 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/medio](bot_aim/heat_kernel_panic_medio.png)

## kernel_panic/novato

- Bolas: 300 en 100 partidas (1 proceso(s), velocidad x1.0, 3215 s de juego en 328 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 295, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 167 | 65.9% |
| 1500 | 32 | 9.5% |
| 500 | 66 | 6.5% |
| 100 | 263 | 5.2% |
| 160 | 115 | 3.6% |
| 225 | 79 | 3.5% |
| 1000 | 11 | 2.2% |
| 140 | 55 | 1.5% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.98 por bola
- `BONUS ### X#`: 0.64 por bola
- `SKILL SHOT ####`: 0.56 por bola
- `SKILL SHOT: AL CARRIL`: 0.56 por bola
- `BOLA #`: 0.42 por bola
- `BONUS ## X#`: 0.18 por bola
- `BONUS X#`: 0.14 por bola
- `PROCESO #/#`: 0.12 por bola
- `BONUS # X#`: 0.06 por bola
- `FORK() LISTO: AL SAUCER`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/novato](bot_aim/heat_kernel_panic_novato.png)

## nautilus/azar

- Bolas: 300 en 99 partidas (1 proceso(s), velocidad x1.0, 4006 s de juego en 553 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 96%, outlane_der 3%.
- Se perdió con kickback listo: 87% de las bolas.
- Bolas salvadas: 232, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 47 | 31.8% |
| 360 | 481 | 23.4% |
| 150 | 622 | 12.6% |
| 100 | 890 | 12.0% |
| 250 | 282 | 9.5% |
| 480 | 105 | 6.8% |
| 50 | 220 | 1.5% |
| 2000 | 5 | 1.4% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.77 por bola
- `SKILL SHOT: AL CARRIL`: 0.62 por bola
- `BONUS ### X#`: 0.60 por bola
- `BONUS ## X#`: 0.37 por bola
- `BOLA #`: 0.33 por bola
- `¡KRAKEN ACTIVO!`: 0.18 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.16 por bola
- `¡KICKBACK!`: 0.13 por bola
- `BONUS #### X#`: 0.03 por bola
- `SKILL SHOT ####`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/azar](bot_aim/heat_nautilus_azar.png)

## nautilus/experto

- Bolas: 300 en 87 partidas (1 proceso(s), velocidad x1.0, 21077 s de juego en 2292 s reales).
- Por dónde se pierde: outlane_izq 32%, centro 17%, outlane_der 51%.
- Se perdió con kickback listo: 29% de las bolas.
- Bolas salvadas: 20, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 561 | 37.2% |
| 150 | 8249 | 16.4% |
| 100 | 11631 | 15.4% |
| 2000 | 320 | 8.5% |
| 480 | 1249 | 8.0% |
| 250 | 1848 | 6.1% |
| 360 | 1019 | 4.9% |
| 50 | 2705 | 1.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡KRAKEN ACTIVO!`: 1.90 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 1.17 por bola
- `SKILL SHOT ####`: 1.07 por bola
- `SKILL SHOT: AL CARRIL`: 1.07 por bola
- `¡KICKBACK!`: 0.71 por bola
- `¡JACKPOT!  ##### M  BONUS X#`: 0.70 por bola
- `BONUS #### X#`: 0.60 por bola
- `BONUS ### X#`: 0.38 por bola
- `BOLA #`: 0.29 por bola
- `¡BOLA EXTRA!`: 0.13 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/experto](bot_aim/heat_nautilus_experto.png)

## nautilus/medio

- Bolas: 300 en 96 partidas (3 proceso(s), velocidad x1.0, 8918 s de juego en 1355 s reales).
- Por dónde se pierde: outlane_izq 15%, centro 64%, outlane_der 21%.
- Se perdió con kickback listo: 53% de las bolas.
- Bolas salvadas: 89, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 200 | 30.6% |
| 2000 | 267 | 16.3% |
| 150 | 3436 | 15.8% |
| 100 | 4280 | 13.1% |
| 360 | 771 | 8.5% |
| 480 | 452 | 6.6% |
| 250 | 779 | 6.0% |
| 50 | 1243 | 1.9% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 0.89 por bola
- `SKILL SHOT: AL CARRIL`: 0.89 por bola
- `¡KRAKEN ACTIVO!`: 0.69 por bola
- `BONUS ### X#`: 0.67 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.62 por bola
- `¡KICKBACK!`: 0.47 por bola
- `BONUS #### X#`: 0.32 por bola
- `BOLA #`: 0.32 por bola
- `¡BOLA SALVADA!`: 0.30 por bola
- `¡JACKPOT!  ##### M  BONUS X#`: 0.05 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/medio](bot_aim/heat_nautilus_medio.png)

## nautilus/novato

- Bolas: 300 en 100 partidas (1 proceso(s), velocidad x1.0, 3209 s de juego en 450 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 100%, outlane_der 0%.
- Se perdió con kickback listo: 90% de las bolas.
- Bolas salvadas: 287, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 178 | 51.7% |
| 360 | 419 | 21.9% |
| 5000 | 10 | 7.3% |
| 250 | 153 | 5.6% |
| 100 | 370 | 5.4% |
| 150 | 219 | 4.8% |
| 480 | 38 | 2.6% |
| 50 | 88 | 0.6% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.96 por bola
- `BONUS ### X#`: 0.68 por bola
- `SKILL SHOT ####`: 0.59 por bola
- `SKILL SHOT: AL CARRIL`: 0.59 por bola
- `BOLA #`: 0.33 por bola
- `BONUS ## X#`: 0.32 por bola
- `¡KICKBACK!`: 0.10 por bola
- `¡KRAKEN ACTIVO!`: 0.06 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.03 por bola
- `BONUS # X#`: 0.00 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/novato](bot_aim/heat_nautilus_novato.png)

