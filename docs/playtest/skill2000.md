# Informe de playtesting skill2000

Generado con `tools/playtest/report.gd` a partir de `skill2000`. Los niveles son de **habilidad del bot**, no de dificultad del juego.

## Resumen

| Mesa / bot | Bolas | Partidas | Puntos por bola (media / mediana / p90) | Puntos por partida (media / mediana / máx) | Segundos por bola (media) |
|---|---:|---:|---|---|---:|
| alicia/azar | 500 | 166 | 1847 / 1050 / 5200 | 6423 / 5391 / 24820 | 13.1 |
| alicia/experto | 500 | 152 | 10440 / 7500 / 20900 | 43859 / 34539 / 153105 | 32.1 |
| alicia/medio | 500 | 165 | 3950 / 3310 / 4610 | 14260 / 10978 / 310588 | 12.0 |
| alicia/novato | 500 | 165 | 2308 / 2000 / 4510 | 7979 / 6776 / 35956 | 10.8 |
| dracula/azar | 500 | 166 | 993 / 770 / 2260 | 3281 / 3179 / 10604 | 12.7 |
| dracula/experto | 500 | 166 | 8719 / 6180 / 14710 | 28685 / 24079 / 163494 | 35.2 |
| dracula/medio | 500 | 166 | 3046 / 3340 / 4260 | 10068 / 9856 / 21893 | 10.7 |
| dracula/novato | 500 | 166 | 1564 / 1810 / 3300 | 5168 / 5016 / 10901 | 10.9 |
| kernel_panic/azar | 500 | 165 | 1416 / 870 / 3405 | 5244 / 4410 / 24956 | 13.0 |
| kernel_panic/experto | 500 | 144 | 8063 / 5825 / 16235 | 37906 / 30622 / 108604 | 26.7 |
| kernel_panic/medio | 500 | 164 | 3527 / 4000 / 5855 | 12652 / 11000 / 51253 | 11.3 |
| kernel_panic/novato | 500 | 166 | 1640 / 2000 / 3710 | 5557 / 5417 / 12527 | 10.7 |
| nautilus/azar | 500 | 166 | 2432 / 1260 / 7550 | 8610 / 5038 / 43881 | 13.2 |
| nautilus/experto | 500 | 160 | 11473 / 6670 / 26340 | 45160 / 39448 / 131488 | 27.9 |
| nautilus/medio | 500 | 166 | 4891 / 5080 / 6760 | 16473 / 15609 / 35131 | 13.9 |
| nautilus/novato | 500 | 166 | 2300 / 2400 / 4720 | 7666 / 6952 / 33627 | 10.9 |

## alicia/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6574 s de juego en 372 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 95%, outlane_der 5%.
- Se perdió con kickback listo: 94% de las bolas.
- Bolas salvadas: 390, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 150 | 1441 | 23.4% |
| 250 | 674 | 18.2% |
| 1500 | 103 | 16.7% |
| 100 | 1404 | 15.2% |
| 300 | 331 | 10.8% |
| 1000 | 93 | 10.1% |
| 2000 | 15 | 3.2% |
| 50 | 232 | 1.3% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.78 por bola
- `SKILL SHOT: AL CARRIL`: 0.59 por bola
- `BONUS ### X#`: 0.50 por bola
- `BOLA #`: 0.41 por bola
- `GRANDE`: 0.39 por bola
- `BONUS ## X#`: 0.33 por bola
- `CHICA`: 0.19 por bola
- `NAIPES COMPLETOS`: 0.19 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `¡KICKBACK!`: 0.06 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/azar](skill2000/heat_alicia_azar.png)

## alicia/experto

- Bolas: 500 en 152 partidas (1 proceso(s), velocidad x1.0, 16060 s de juego en 873 s reales).
- Por dónde se pierde: outlane_izq 6%, centro 61%, outlane_der 33%.
- Se perdió con kickback listo: 76% de las bolas.
- Bolas salvadas: 148, TILT: 0, bolas trabadas: 2, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 685 | 26.2% |
| 250 | 4618 | 22.1% |
| 300 | 2039 | 11.7% |
| 1000 | 518 | 9.9% |
| 100 | 5085 | 9.7% |
| 1500 | 336 | 9.7% |
| 150 | 2562 | 7.4% |
| 10 | 5735 | 1.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT: AL CARRIL`: 1.37 por bola
- `SKILL SHOT ####`: 1.37 por bola
- `NAIPES COMPLETOS`: 1.04 por bola
- `GRANDE`: 0.82 por bola
- `CHICA`: 0.69 por bola
- `BONUS ### X#`: 0.66 por bola
- `BONUS #### X#`: 0.34 por bola
- `LOCK ENCENDIDO`: 0.31 por bola
- `BOLA #`: 0.30 por bola
- `¡BOLA SALVADA!`: 0.30 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/experto](skill2000/heat_alicia_experto.png)

## alicia/medio

- Bolas: 500 en 165 partidas (1 proceso(s), velocidad x1.0, 5983 s de juego en 384 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 96% de las bolas.
- Bolas salvadas: 462, TILT: 0, bolas trabadas: 1, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 657 | 66.5% |
| 300 | 656 | 10.0% |
| 100 | 1034 | 5.2% |
| 150 | 675 | 5.1% |
| 1000 | 99 | 5.0% |
| 250 | 371 | 4.7% |
| 1500 | 39 | 3.0% |
| 50 | 88 | 0.2% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT: AL CARRIL`: 1.31 por bola
- `SKILL SHOT ####`: 1.31 por bola
- `¡BOLA SALVADA!`: 0.92 por bola
- `BONUS ### X#`: 0.90 por bola
- `BOLA #`: 0.38 por bola
- `NAIPES COMPLETOS`: 0.20 por bola
- `GRANDE`: 0.16 por bola
- `CHICA`: 0.11 por bola
- `TAMAÑO NORMAL`: 0.07 por bola
- `¡KICKBACK!`: 0.04 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/medio](skill2000/heat_alicia_medio.png)

## alicia/novato

- Bolas: 500 en 165 partidas (1 proceso(s), velocidad x1.0, 5424 s de juego en 372 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 481, TILT: 0, bolas trabadas: 4, rescates por escape: 0, máximo de bolas a la vez: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 259 | 44.9% |
| 150 | 1344 | 17.5% |
| 1500 | 99 | 12.9% |
| 100 | 951 | 8.2% |
| 1000 | 88 | 7.6% |
| 300 | 226 | 5.9% |
| 250 | 113 | 2.4% |
| 50 | 100 | 0.4% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.96 por bola
- `BONUS ### X#`: 0.69 por bola
- `SKILL SHOT ####`: 0.52 por bola
- `SKILL SHOT: AL CARRIL`: 0.52 por bola
- `BOLA #`: 0.41 por bola
- `GRANDE`: 0.31 por bola
- `NAIPES COMPLETOS`: 0.18 por bola
- `BONUS ## X#`: 0.17 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `CHICA`: 0.10 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/novato](skill2000/heat_alicia_novato.png)

## dracula/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6375 s de juego en 492 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 98%, outlane_der 2%.
- Se perdió con kickback listo: 93% de las bolas.
- Bolas salvadas: 378, TILT: 0, bolas trabadas: 7, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 966 | 48.6% |
| 100 | 861 | 17.3% |
| 300 | 244 | 14.7% |
| 150 | 182 | 5.5% |
| 2000 | 13 | 5.2% |
| 50 | 411 | 4.1% |
| 500 | 20 | 2.0% |
| 10 | 807 | 1.6% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.76 por bola
- `SKILL SHOT: AL CARRIL`: 0.56 por bola
- `BOLA #`: 0.43 por bola
- `BONUS ### X#`: 0.42 por bola
- `BONUS ## X#`: 0.38 por bola
- `¡KICKBACK!`: 0.07 por bola
- `BONUS # X#`: 0.06 por bola
- `CARFAX #/#`: 0.04 por bola
- `SKILL SHOT ####`: 0.03 por bola
- `BOLA DESTRABADA`: 0.01 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/azar](skill2000/heat_dracula_azar.png)

## dracula/experto

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 17620 s de juego en 1222 s reales).
- Por dónde se pierde: outlane_izq 4%, centro 68%, outlane_der 27%.
- Se perdió con kickback listo: 74% de las bolas.
- Bolas salvadas: 142, TILT: 0, bolas trabadas: 20, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 5637 | 32.3% |
| 2000 | 695 | 31.9% |
| 100 | 4172 | 9.6% |
| 300 | 1209 | 8.3% |
| 5000 | 63 | 7.2% |
| 150 | 875 | 3.0% |
| 1000 | 101 | 2.3% |
| 50 | 2020 | 2.3% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.39 por bola
- `SKILL SHOT: AL CARRIL`: 1.39 por bola
- `BONUS ### X#`: 0.78 por bola
- `BOLA #`: 0.33 por bola
- `¡BOLA SALVADA!`: 0.28 por bola
- `¡KICKBACK!`: 0.26 por bola
- `BONUS #### X#`: 0.22 por bola
- `CARFAX #/#`: 0.20 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `¡JACKPOT!  ####`: 0.13 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/experto](skill2000/heat_dracula_experto.png)

## dracula/medio

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5354 s de juego en 433 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 98%, outlane_der 2%.
- Se perdió con kickback listo: 99% de las bolas.
- Bolas salvadas: 465, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 665 | 87.3% |
| 250 | 433 | 7.1% |
| 300 | 105 | 2.1% |
| 100 | 293 | 1.9% |
| 50 | 175 | 0.6% |
| 150 | 50 | 0.5% |
| 10 | 404 | 0.3% |
| 500 | 5 | 0.2% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.33 por bola
- `SKILL SHOT: AL CARRIL`: 1.33 por bola
- `¡BOLA SALVADA!`: 0.93 por bola
- `BONUS ### X#`: 0.91 por bola
- `BOLA #`: 0.38 por bola
- `BONUS ## X#`: 0.01 por bola
- `¡KICKBACK!`: 0.01 por bola
- `CARFAX #/#`: 0.01 por bola
- `BOLA ENCERRADA`: 0.00 por bola
- `BOLAS LIBERADAS`: 0.00 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/medio](skill2000/heat_dracula_medio.png)

## dracula/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5435 s de juego en 434 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 100%, outlane_der 0%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 488, TILT: 0, bolas trabadas: 12, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 267 | 68.3% |
| 250 | 306 | 9.8% |
| 100 | 603 | 7.7% |
| 500 | 64 | 4.1% |
| 150 | 191 | 3.7% |
| 300 | 84 | 3.2% |
| 1000 | 13 | 1.7% |
| 50 | 201 | 1.3% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.98 por bola
- `BONUS ### X#`: 0.61 por bola
- `SKILL SHOT ####`: 0.53 por bola
- `SKILL SHOT: AL CARRIL`: 0.53 por bola
- `BOLA #`: 0.41 por bola
- `BONUS ## X#`: 0.23 por bola
- `CARFAX #/#`: 0.14 por bola
- `BONUS # X#`: 0.05 por bola
- `BOLA DESTRABADA`: 0.02 por bola
- `¡KICKBACK!`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/novato](skill2000/heat_dracula_novato.png)

## kernel_panic/azar

- Bolas: 500 en 165 partidas (1 proceso(s), velocidad x1.0, 6490 s de juego en 416 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 92%, outlane_der 8%.
- Se perdió con kickback listo: 89% de las bolas.
- Bolas salvadas: 390, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 1500 | 97 | 20.6% |
| 1000 | 135 | 19.1% |
| 100 | 1284 | 18.1% |
| 225 | 454 | 14.4% |
| 160 | 351 | 7.9% |
| 500 | 102 | 7.2% |
| 2000 | 14 | 4.0% |
| 140 | 173 | 3.4% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.78 por bola
- `SKILL SHOT: AL CARRIL`: 0.54 por bola
- `BONUS ### X#`: 0.47 por bola
- `BONUS X#`: 0.46 por bola
- `BOLA #`: 0.41 por bola
- `BONUS ## X#`: 0.32 por bola
- `PROCESO #/#`: 0.25 por bola
- `FORK() LISTO: AL SAUCER`: 0.13 por bola
- `¡KICKBACK!`: 0.11 por bola
- `BONUS # X#`: 0.07 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/azar](skill2000/heat_kernel_panic_azar.png)

## kernel_panic/experto

- Bolas: 500 en 144 partidas (1 proceso(s), velocidad x1.0, 13344 s de juego en 985 s reales).
- Por dónde se pierde: outlane_izq 26%, centro 40%, outlane_der 34%.
- Se perdió con kickback listo: 43% de las bolas.
- Bolas salvadas: 163, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 660 | 32.7% |
| 1000 | 772 | 19.2% |
| 100 | 5366 | 13.3% |
| 225 | 2201 | 12.3% |
| 1500 | 233 | 8.7% |
| 500 | 386 | 4.8% |
| 160 | 995 | 3.9% |
| 140 | 430 | 1.5% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `BONUS X#`: 1.68 por bola
- `SKILL SHOT ####`: 1.32 por bola
- `SKILL SHOT: AL CARRIL`: 1.32 por bola
- `BONUS ### X#`: 0.74 por bola
- `¡KICKBACK!`: 0.57 por bola
- `PROCESO #/#`: 0.45 por bola
- `FORK() LISTO: AL SAUCER`: 0.40 por bola
- `¡BOLA SALVADA!`: 0.33 por bola
- `BOLA #`: 0.29 por bola
- `BONUS #### X#`: 0.26 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/experto](skill2000/heat_kernel_panic_experto.png)

## kernel_panic/medio

- Bolas: 500 en 164 partidas (1 proceso(s), velocidad x1.0, 5657 s de juego en 369 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 95%, outlane_der 4%.
- Se perdió con kickback listo: 94% de las bolas.
- Bolas salvadas: 441, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 653 | 74.1% |
| 1000 | 122 | 6.9% |
| 225 | 366 | 4.7% |
| 1500 | 53 | 4.5% |
| 100 | 682 | 3.9% |
| 160 | 218 | 2.0% |
| 500 | 61 | 1.7% |
| 5000 | 2 | 0.6% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.31 por bola
- `SKILL SHOT: AL CARRIL`: 1.31 por bola
- `BONUS ### X#`: 0.90 por bola
- `¡BOLA SALVADA!`: 0.88 por bola
- `BOLA #`: 0.38 por bola
- `BONUS X#`: 0.34 por bola
- `PROCESO #/#`: 0.12 por bola
- `FORK() LISTO: AL SAUCER`: 0.10 por bola
- `¡KICKBACK!`: 0.06 por bola
- `SEGFAULT: FIN DE LA MULTIBOLA`: 0.03 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/medio](skill2000/heat_kernel_panic_medio.png)

## kernel_panic/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5332 s de juego en 342 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 493, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 261 | 63.6% |
| 1500 | 52 | 9.5% |
| 100 | 489 | 6.0% |
| 500 | 92 | 5.6% |
| 160 | 210 | 4.1% |
| 225 | 135 | 3.7% |
| 1000 | 30 | 3.7% |
| 140 | 98 | 1.7% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.99 por bola
- `BONUS ### X#`: 0.62 por bola
- `SKILL SHOT ####`: 0.52 por bola
- `SKILL SHOT: AL CARRIL`: 0.52 por bola
- `BOLA #`: 0.41 por bola
- `BONUS ## X#`: 0.20 por bola
- `BONUS X#`: 0.16 por bola
- `PROCESO #/#`: 0.13 por bola
- `BONUS # X#`: 0.06 por bola
- `FORK() LISTO: AL SAUCER`: 0.03 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/novato](skill2000/heat_kernel_panic_novato.png)

## nautilus/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6594 s de juego en 629 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 96%, outlane_der 3%.
- Se perdió con kickback listo: 88% de las bolas.
- Bolas salvadas: 391, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 74 | 30.4% |
| 360 | 814 | 24.1% |
| 150 | 1028 | 12.7% |
| 100 | 1461 | 12.0% |
| 250 | 455 | 9.4% |
| 480 | 164 | 6.5% |
| 2000 | 16 | 2.6% |
| 50 | 355 | 1.5% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.78 por bola
- `BONUS ### X#`: 0.61 por bola
- `SKILL SHOT: AL CARRIL`: 0.59 por bola
- `BONUS ## X#`: 0.36 por bola
- `BOLA #`: 0.33 por bola
- `¡KRAKEN ACTIVO!`: 0.17 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.15 por bola
- `¡KICKBACK!`: 0.12 por bola
- `SKILL SHOT ####`: 0.03 por bola
- `BONUS #### X#`: 0.03 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/azar](skill2000/heat_nautilus_azar.png)

## nautilus/experto

- Bolas: 500 en 160 partidas (1 proceso(s), velocidad x1.0, 13952 s de juego en 1387 s reales).
- Por dónde se pierde: outlane_izq 7%, centro 63%, outlane_der 30%.
- Se perdió con kickback listo: 55% de las bolas.
- Bolas salvadas: 114, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 342 | 29.8% |
| 2000 | 612 | 21.3% |
| 150 | 5086 | 13.3% |
| 100 | 6820 | 11.9% |
| 360 | 1325 | 8.3% |
| 480 | 810 | 6.8% |
| 250 | 1333 | 5.8% |
| 50 | 2010 | 1.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.22 por bola
- `SKILL SHOT: AL CARRIL`: 1.22 por bola
- `¡KRAKEN ACTIVO!`: 0.72 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.66 por bola
- `BONUS ### X#`: 0.64 por bola
- `¡KICKBACK!`: 0.45 por bola
- `BONUS #### X#`: 0.36 por bola
- `BOLA #`: 0.32 por bola
- `¡BOLA SALVADA!`: 0.23 por bola
- `¡BOLA EXTRA!`: 0.04 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/experto](skill2000/heat_nautilus_experto.png)

## nautilus/medio

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6945 s de juego en 699 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 95%, outlane_der 3%.
- Se perdió con kickback listo: 89% de las bolas.
- Bolas salvadas: 408, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 624 | 51.0% |
| 360 | 1409 | 20.7% |
| 5000 | 44 | 9.0% |
| 100 | 1303 | 5.3% |
| 150 | 830 | 5.1% |
| 250 | 426 | 4.4% |
| 480 | 132 | 2.6% |
| 50 | 720 | 1.5% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.25 por bola
- `SKILL SHOT: AL CARRIL`: 1.25 por bola
- `BONUS ### X#`: 0.93 por bola
- `¡BOLA SALVADA!`: 0.82 por bola
- `BOLA #`: 0.33 por bola
- `¡KRAKEN ACTIVO!`: 0.12 por bola
- `¡KICKBACK!`: 0.11 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.09 por bola
- `BONUS #### X#`: 0.05 por bola
- `BONUS ## X#`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/medio](skill2000/heat_nautilus_medio.png)

## nautilus/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5474 s de juego en 513 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 92% de las bolas.
- Bolas salvadas: 476, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 2000 | 262 | 45.6% |
| 360 | 686 | 21.5% |
| 5000 | 27 | 11.7% |
| 250 | 308 | 6.7% |
| 100 | 683 | 5.9% |
| 150 | 390 | 5.1% |
| 480 | 60 | 2.5% |
| 50 | 175 | 0.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.95 por bola
- `BONUS ### X#`: 0.65 por bola
- `SKILL SHOT ####`: 0.52 por bola
- `SKILL SHOT: AL CARRIL`: 0.52 por bola
- `BONUS ## X#`: 0.35 por bola
- `BOLA #`: 0.33 por bola
- `¡KICKBACK!`: 0.08 por bola
- `¡KRAKEN ACTIVO!`: 0.08 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.05 por bola
- `BONUS #### X#`: 0.01 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/novato](skill2000/heat_nautilus_novato.png)

