# Informe de playtesting base

Generado con `tools/playtest/report.gd` a partir de `base`. Los niveles son de **habilidad del bot**, no de dificultad del juego.

## Resumen

| Mesa / bot | Bolas | Partidas | Puntos por bola (media / mediana / p90) | Puntos por partida (media / mediana / máx) | Segundos por bola (media) |
|---|---:|---:|---|---|---:|
| alicia/azar | 500 | 161 | 5347 / 3850 / 10920 | 20562 / 17221 / 75189 | 33.0 |
| alicia/experto | 500 | 154 | 15907 / 13590 / 26790 | 64128 / 54880 / 163256 | 34.7 |
| alicia/medio | 61 | 19 | 19200 / 11750 / 32950 | 76866 / 58882 / 321289 | 37.0 |
| alicia/novato | 4 | 1 | 57390 / 27970 / 139990 | 334705 / 334705 / 334705 | 180.6 |
| dracula/azar | 500 | 166 | 2816 / 2060 / 5750 | 9370 / 8459 / 25872 | 32.9 |
| dracula/experto | 500 | 166 | 12984 / 10740 / 22070 | 44202 / 40106 / 157461 | 36.1 |
| dracula/medio | 56 | 18 | 21019 / 12990 / 44280 | 66628 / 48400 / 212509 | 41.3 |
| dracula/novato | 115 | 35 | 68281 / 43590 / 154360 | 296660 / 230724 / 759128 | 221.8 |
| kernel_panic/azar | 500 | 158 | 3991 / 3250 / 8345 | 16363 / 14808 / 52849 | 34.4 |
| kernel_panic/experto | 500 | 138 | 14498 / 12440 / 25325 | 71153 / 71634 / 163394 | 32.4 |
| kernel_panic/medio | 149 | 44 | 15172 / 12820 / 30175 | 66880 / 57953 / 165711 | 28.4 |
| kernel_panic/novato | 4 | 1 | 41469 / 1870 / 143395 | 26636 / 26636 / 26636 | 141.8 |
| nautilus/azar | 500 | 165 | 6981 / 5440 / 14790 | 25381 / 22041 / 72339 | 32.7 |
| nautilus/experto | 500 | 158 | 16444 / 12780 / 32580 | 64842 / 52867 / 221432 | 30.2 |
| nautilus/medio | 42 | 14 | 30195 / 20040 / 96580 | 106516 / 78542 / 234605 | 45.5 |
| nautilus/novato | 174 | 51 | 55667 / 32310 / 128000 | 261321 / 171514 / 912435 | 137.2 |

## alicia/azar

- Bolas: 500 en 161 partidas (1 proceso(s), velocidad x1.0, 16502 s de juego en 840 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 94%, outlane_der 5%.
- Se perdió con kickback listo: 85% de las bolas.
- Bolas salvadas: 1774, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 150 | 3002 | 16.8% |
| 250 | 1709 | 16.0% |
| 1500 | 281 | 15.8% |
| 300 | 1398 | 15.7% |
| 1000 | 368 | 13.8% |
| 100 | 3491 | 13.1% |
| 5000 | 35 | 6.5% |
| 50 | 588 | 1.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 3.55 por bola
- `SKILL SHOT: AL CARRIL`: 1.47 por bola
- `GRANDE`: 0.78 por bola
- `BONUS ### X#`: 0.75 por bola
- `NAIPES COMPLETOS`: 0.74 por bola
- `CHICA`: 0.50 por bola
- `BOLA #`: 0.32 por bola
- `LOCK ENCENDIDO`: 0.30 por bola
- `TAMAÑO NORMAL`: 0.17 por bola
- `¡KICKBACK!`: 0.15 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/azar](base/heat_alicia_azar.png)

## alicia/experto

- Bolas: 500 en 154 partidas (1 proceso(s), velocidad x1.0, 17328 s de juego en 1033 s reales).
- Por dónde se pierde: outlane_izq 7%, centro 61%, outlane_der 31%.
- Se perdió con kickback listo: 71% de las bolas.
- Bolas salvadas: 262, TILT: 0, bolas trabadas: 1, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 790 | 49.7% |
| 250 | 5058 | 15.9% |
| 300 | 2145 | 8.1% |
| 1000 | 534 | 6.7% |
| 100 | 5294 | 6.7% |
| 1500 | 342 | 6.4% |
| 150 | 2568 | 4.8% |
| 10 | 6196 | 0.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT: AL CARRIL`: 1.58 por bola
- `SKILL SHOT ####`: 1.58 por bola
- `NAIPES COMPLETOS`: 1.07 por bola
- `GRANDE`: 0.88 por bola
- `BONUS #### X#`: 0.70 por bola
- `CHICA`: 0.69 por bola
- `¡BOLA SALVADA!`: 0.52 por bola
- `LOCK ENCENDIDO`: 0.32 por bola
- `BOLA #`: 0.31 por bola
- `BONUS ### X#`: 0.30 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/experto](base/heat_alicia_experto.png)

## alicia/medio

- Bolas: 61 en 19 partidas (1 proceso(s), velocidad x1.0, 3158 s de juego en 215 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 93%, outlane_der 7%.
- Se perdió con kickback listo: 79% de las bolas.
- Bolas salvadas: 333, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 272 | 73.0% |
| 300 | 371 | 6.0% |
| 250 | 412 | 5.5% |
| 100 | 760 | 4.1% |
| 1000 | 69 | 3.7% |
| 1500 | 45 | 3.6% |
| 150 | 426 | 3.4% |
| 50 | 131 | 0.4% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 5.46 por bola
- `SKILL SHOT: AL CARRIL`: 4.46 por bola
- `SKILL SHOT ####`: 4.46 por bola
- `NAIPES COMPLETOS`: 1.13 por bola
- `GRANDE`: 1.03 por bola
- `CHICA`: 0.80 por bola
- `BONUS #### X#`: 0.56 por bola
- `TAMAÑO NORMAL`: 0.52 por bola
- `BONUS ### X#`: 0.39 por bola
- `BOLA #`: 0.31 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/medio](base/heat_alicia_medio.png)

## alicia/novato

- Bolas: 4 en 1 partidas (1 proceso(s), velocidad x1.0, 1622 s de juego en 106 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 100%, outlane_der 0%.
- Se perdió con kickback listo: 75% de las bolas.
- Bolas salvadas: 292, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 59 | 56.7% |
| 1500 | 43 | 12.4% |
| 300 | 165 | 9.5% |
| 1000 | 39 | 7.5% |
| 150 | 204 | 5.9% |
| 100 | 245 | 4.7% |
| 250 | 49 | 2.4% |
| 500 | 4 | 0.4% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 73.00 por bola
- `SKILL SHOT: AL CARRIL`: 15.00 por bola
- `SKILL SHOT ####`: 14.75 por bola
- `NAIPES COMPLETOS`: 9.75 por bola
- `GRANDE`: 6.75 por bola
- `TAMAÑO NORMAL`: 4.75 por bola
- `CHICA`: 3.00 por bola
- `LOCK ENCENDIDO`: 1.25 por bola
- `BOLA ENCERRADA`: 1.00 por bola
- `BOLAS LIBERADAS`: 1.00 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/novato](base/heat_alicia_novato.png)

## dracula/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 16474 s de juego en 1206 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 96%, outlane_der 3%.
- Se perdió con kickback listo: 86% de las bolas.
- Bolas salvadas: 1784, TILT: 0, bolas trabadas: 21, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 2442 | 43.4% |
| 100 | 2208 | 15.7% |
| 5000 | 40 | 14.2% |
| 300 | 598 | 12.7% |
| 150 | 491 | 5.2% |
| 50 | 1031 | 3.7% |
| 1000 | 25 | 1.8% |
| 500 | 49 | 1.7% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 3.57 por bola
- `SKILL SHOT: AL CARRIL`: 1.51 por bola
- `BONUS ### X#`: 0.86 por bola
- `BOLA #`: 0.33 por bola
- `¡KICKBACK!`: 0.14 por bola
- `BONUS ## X#`: 0.13 por bola
- `CARFAX #/#`: 0.09 por bola
- `SKILL SHOT ####`: 0.08 por bola
- `BOLA DESTRABADA`: 0.04 por bola
- `LOCK ENCENDIDO`: 0.04 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/azar](base/heat_dracula_azar.png)

## dracula/experto

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 18055 s de juego en 1420 s reales).
- Por dónde se pierde: outlane_izq 7%, centro 67%, outlane_der 27%.
- Se perdió con kickback listo: 73% de las bolas.
- Bolas salvadas: 190, TILT: 0, bolas trabadas: 10, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 758 | 58.4% |
| 250 | 5801 | 22.3% |
| 100 | 4294 | 6.6% |
| 300 | 1205 | 5.6% |
| 150 | 917 | 2.1% |
| 50 | 2032 | 1.6% |
| 1000 | 88 | 1.4% |
| 500 | 127 | 1.0% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.48 por bola
- `SKILL SHOT: AL CARRIL`: 1.48 por bola
- `BONUS #### X#`: 0.53 por bola
- `BONUS ### X#`: 0.47 por bola
- `¡BOLA SALVADA!`: 0.38 por bola
- `BOLA #`: 0.33 por bola
- `¡KICKBACK!`: 0.27 por bola
- `CARFAX #/#`: 0.20 por bola
- `LOCK ENCENDIDO`: 0.12 por bola
- `BOLA ENCERRADA`: 0.11 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/experto](base/heat_dracula_experto.png)

## dracula/medio

- Bolas: 56 en 18 partidas (1 proceso(s), velocidad x1.0, 3213 s de juego en 250 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 96%, outlane_der 4%.
- Se perdió con kickback listo: 89% de las bolas.
- Bolas salvadas: 441, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 337 | 89.9% |
| 250 | 422 | 5.6% |
| 300 | 104 | 1.7% |
| 100 | 291 | 1.6% |
| 50 | 174 | 0.5% |
| 150 | 49 | 0.4% |
| 10 | 381 | 0.2% |
| 500 | 5 | 0.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 7.88 por bola
- `SKILL SHOT ####`: 6.02 por bola
- `SKILL SHOT: AL CARRIL`: 6.02 por bola
- `BONUS #### X#`: 0.68 por bola
- `BOLA #`: 0.32 por bola
- `BONUS ### X#`: 0.30 por bola
- `¡KICKBACK!`: 0.11 por bola
- `CARFAX #/#`: 0.07 por bola
- `BOLA ENCERRADA`: 0.02 por bola
- `BOLAS LIBERADAS`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/medio](base/heat_dracula_medio.png)

## dracula/novato

- Bolas: 115 en 35 partidas (1 proceso(s), velocidad x1.0, 26410 s de juego en 1893 s reales).
- Por dónde se pierde: outlane_izq 6%, centro 94%, outlane_der 0%.
- Se perdió con kickback listo: 76% de las bolas.
- Bolas salvadas: 4718, TILT: 0, bolas trabadas: 66, rescates por escape: 0, máximo de bolas a la vez: 2, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 1351 | 83.6% |
| 250 | 1438 | 4.4% |
| 100 | 2717 | 3.4% |
| 1000 | 171 | 2.1% |
| 1500 | 98 | 1.8% |
| 150 | 854 | 1.6% |
| 300 | 363 | 1.3% |
| 500 | 176 | 1.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 41.03 por bola
- `SKILL SHOT ####`: 11.75 por bola
- `SKILL SHOT: AL CARRIL`: 11.75 por bola
- `CARFAX #/#`: 2.03 por bola
- `¡CARFAX!  BONUS X#`: 0.85 por bola
- `BONUS #### X#`: 0.69 por bola
- `BOLA DESTRABADA`: 0.57 por bola
- `LOCK ENCENDIDO`: 0.50 por bola
- `BOLA ENCERRADA`: 0.48 por bola
- `BOLAS LIBERADAS`: 0.48 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/novato](base/heat_dracula_novato.png)

## kernel_panic/azar

- Bolas: 500 en 158 partidas (1 proceso(s), velocidad x1.0, 17184 s de juego en 1042 s reales).
- Por dónde se pierde: outlane_izq 3%, centro 88%, outlane_der 9%.
- Se perdió con kickback listo: 65% de las bolas.
- Bolas salvadas: 1890, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 1000 | 396 | 19.8% |
| 1500 | 258 | 19.4% |
| 100 | 3217 | 16.1% |
| 225 | 1210 | 13.6% |
| 5000 | 32 | 8.0% |
| 500 | 306 | 7.7% |
| 160 | 952 | 7.6% |
| 140 | 419 | 2.9% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 3.78 por bola
- `SKILL SHOT: AL CARRIL`: 1.51 por bola
- `BONUS X#`: 1.27 por bola
- `BONUS ### X#`: 0.77 por bola
- `PROCESO #/#`: 0.43 por bola
- `¡KICKBACK!`: 0.35 por bola
- `FORK() LISTO: AL SAUCER`: 0.35 por bola
- `BOLA #`: 0.32 por bola
- `SEGFAULT: FIN DE LA MULTIBOLA`: 0.18 por bola
- `¡FORK()!  MULTIBOLA`: 0.18 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/azar](base/heat_kernel_panic_azar.png)

## kernel_panic/experto

- Bolas: 500 en 138 partidas (1 proceso(s), velocidad x1.0, 16206 s de juego en 1138 s reales).
- Por dónde se pierde: outlane_izq 26%, centro 38%, outlane_der 36%.
- Se perdió con kickback listo: 36% de las bolas.
- Bolas salvadas: 262, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 764 | 52.7% |
| 1000 | 955 | 13.2% |
| 100 | 6874 | 9.5% |
| 225 | 2686 | 8.3% |
| 1500 | 312 | 6.5% |
| 500 | 529 | 3.6% |
| 160 | 1282 | 2.8% |
| 140 | 592 | 1.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `BONUS X#`: 2.04 por bola
- `SKILL SHOT ####`: 1.52 por bola
- `SKILL SHOT: AL CARRIL`: 1.52 por bola
- `BONUS #### X#`: 0.65 por bola
- `¡KICKBACK!`: 0.64 por bola
- `PROCESO #/#`: 0.55 por bola
- `¡BOLA SALVADA!`: 0.52 por bola
- `FORK() LISTO: AL SAUCER`: 0.50 por bola
- `BONUS ### X#`: 0.35 por bola
- `SEGFAULT: FIN DE LA MULTIBOLA`: 0.32 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/experto](base/heat_kernel_panic_experto.png)

## kernel_panic/medio

- Bolas: 149 en 44 partidas (1 proceso(s), velocidad x1.0, 5139 s de juego en 340 s reales).
- Por dónde se pierde: outlane_izq 8%, centro 78%, outlane_der 14%.
- Se perdió con kickback listo: 52% de las bolas.
- Bolas salvadas: 487, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 429 | 73.9% |
| 1000 | 205 | 7.1% |
| 1500 | 84 | 4.3% |
| 225 | 555 | 4.3% |
| 100 | 1169 | 4.0% |
| 500 | 155 | 2.7% |
| 160 | 388 | 2.1% |
| 140 | 108 | 0.5% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 3.27 por bola
- `SKILL SHOT ####`: 2.88 por bola
- `SKILL SHOT: AL CARRIL`: 2.88 por bola
- `BONUS X#`: 1.80 por bola
- `BONUS #### X#`: 0.58 por bola
- `PROCESO #/#`: 0.53 por bola
- `FORK() LISTO: AL SAUCER`: 0.49 por bola
- `¡KICKBACK!`: 0.48 por bola
- `BONUS ### X#`: 0.41 por bola
- `BOLA #`: 0.30 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/medio](base/heat_kernel_panic_medio.png)

## kernel_panic/novato

- Bolas: 4 en 1 partidas (1 proceso(s), velocidad x1.0, 1467 s de juego en 90 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 100%, outlane_der 0%.
- Se perdió con kickback listo: 75% de las bolas.
- Bolas salvadas: 267, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 60 | 75.0% |
| 1500 | 18 | 6.7% |
| 100 | 158 | 3.9% |
| 500 | 29 | 3.6% |
| 1000 | 12 | 3.0% |
| 160 | 73 | 2.9% |
| 225 | 41 | 2.3% |
| 140 | 33 | 1.2% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 66.75 por bola
- `SKILL SHOT ####`: 15.00 por bola
- `SKILL SHOT: AL CARRIL`: 15.00 por bola
- `BONUS X#`: 2.25 por bola
- `PROCESO #/#`: 2.25 por bola
- `FORK() LISTO: AL SAUCER`: 2.00 por bola
- `SEGFAULT: FIN DE LA MULTIBOLA`: 1.75 por bola
- `¡FORK()!  MULTIBOLA`: 1.75 por bola
- `BONUS ### X#`: 0.50 por bola
- `¡KICKBACK!`: 0.50 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/novato](base/heat_kernel_panic_novato.png)

## nautilus/azar

- Bolas: 500 en 165 partidas (1 proceso(s), velocidad x1.0, 16338 s de juego en 1494 s reales).
- Por dónde se pierde: outlane_izq 2%, centro 91%, outlane_der 7%.
- Se perdió con kickback listo: 70% de las bolas.
- Bolas salvadas: 1733, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 297 | 42.5% |
| 360 | 2018 | 20.8% |
| 150 | 2634 | 11.3% |
| 100 | 3751 | 10.7% |
| 250 | 1013 | 7.3% |
| 480 | 383 | 5.3% |
| 50 | 931 | 1.3% |
| 10 | 2542 | 0.7% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 3.47 por bola
- `SKILL SHOT: AL CARRIL`: 1.49 por bola
- `BONUS ### X#`: 0.74 por bola
- `¡KRAKEN ACTIVO!`: 0.54 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.52 por bola
- `BOLA #`: 0.33 por bola
- `¡KICKBACK!`: 0.30 por bola
- `BONUS #### X#`: 0.23 por bola
- `SKILL SHOT ####`: 0.08 por bola
- `BONUS ## X#`: 0.03 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/azar](base/heat_nautilus_azar.png)

## nautilus/experto

- Bolas: 500 en 158 partidas (1 proceso(s), velocidad x1.0, 15113 s de juego en 1544 s reales).
- Por dónde se pierde: outlane_izq 6%, centro 66%, outlane_der 29%.
- Se perdió con kickback listo: 59% de las bolas.
- Bolas salvadas: 156, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 1036 | 63.0% |
| 150 | 5392 | 9.8% |
| 100 | 7338 | 8.9% |
| 360 | 1471 | 6.4% |
| 480 | 898 | 5.2% |
| 250 | 1458 | 4.4% |
| 50 | 2237 | 1.4% |
| 10 | 6245 | 0.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.31 por bola
- `SKILL SHOT: AL CARRIL`: 1.31 por bola
- `¡KRAKEN ACTIVO!`: 0.80 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.68 por bola
- `BONUS #### X#`: 0.55 por bola
- `BONUS ### X#`: 0.45 por bola
- `¡KICKBACK!`: 0.41 por bola
- `BOLA #`: 0.32 por bola
- `¡BOLA SALVADA!`: 0.31 por bola
- `¡JACKPOT!  ##### M  BONUS X#`: 0.08 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/experto](base/heat_nautilus_experto.png)

## nautilus/medio

- Bolas: 42 en 14 partidas (1 proceso(s), velocidad x1.0, 2812 s de juego en 262 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 98%, outlane_der 2%.
- Se perdió con kickback listo: 76% de las bolas.
- Bolas salvadas: 404, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 336 | 83.7% |
| 360 | 598 | 10.7% |
| 100 | 339 | 1.7% |
| 150 | 187 | 1.4% |
| 250 | 85 | 1.1% |
| 480 | 34 | 0.8% |
| 50 | 198 | 0.5% |
| 10 | 242 | 0.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 9.62 por bola
- `SKILL SHOT ####`: 7.55 por bola
- `SKILL SHOT: AL CARRIL`: 7.55 por bola
- `BONUS #### X#`: 0.64 por bola
- `¡KRAKEN ACTIVO!`: 0.48 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.45 por bola
- `BOLA #`: 0.33 por bola
- `BONUS ### X#`: 0.29 por bola
- `¡KICKBACK!`: 0.24 por bola
- `BONUS ##### X#`: 0.07 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/medio](base/heat_nautilus_medio.png)

## nautilus/novato

- Bolas: 174 en 51 partidas (1 proceso(s), velocidad x1.0, 24775 s de juego en 2173 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 89%, outlane_der 11%.
- Se perdió con kickback listo: 47% de las bolas.
- Bolas salvadas: 4295, TILT: 0, bolas trabadas: 20, rescates por escape: 0, máximo de bolas a la vez: 3, sesiones cortadas por tope: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 1567 | 78.4% |
| 360 | 3198 | 11.5% |
| 100 | 3296 | 3.3% |
| 250 | 1058 | 2.6% |
| 150 | 1614 | 2.4% |
| 480 | 251 | 1.2% |
| 50 | 764 | 0.4% |
| 10 | 1087 | 0.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 24.68 por bola
- `SKILL SHOT ####`: 7.14 por bola
- `SKILL SHOT: AL CARRIL`: 7.14 por bola
- `¡KRAKEN ACTIVO!`: 1.90 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 1.32 por bola
- `BONUS #### X#`: 0.66 por bola
- `¡JACKPOT!  ##### M  BONUS X#`: 0.55 por bola
- `¡KICKBACK!`: 0.53 por bola
- `BOLA #`: 0.29 por bola
- `BONUS ##### X#`: 0.19 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/novato](base/heat_nautilus_novato.png)

