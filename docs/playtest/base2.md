# Informe de playtesting base2

Generado con `tools/playtest/report.gd` a partir de `base2`. Los niveles son de **habilidad del bot**, no de dificultad del juego.

## Resumen

| Mesa / bot | Bolas | Partidas | Puntos por bola (media / mediana / p90) | Puntos por partida (media / mediana / máx) | Segundos por bola (media) |
|---|---:|---:|---|---|---:|
| alicia/azar | 500 | 166 | 1957 / 980 / 5520 | 6698 / 6028 / 24813 | 13.2 |
| alicia/experto | 500 | 153 | 15487 / 11530 / 26990 | 63940 / 47546 / 373326 | 34.6 |
| alicia/medio | 500 | 165 | 8710 / 7910 / 11810 | 30480 / 27192 / 287007 | 14.1 |
| alicia/novato | 500 | 166 | 3857 / 5000 / 7750 | 12972 / 12892 / 36825 | 10.8 |
| dracula/azar | 500 | 166 | 1071 / 770 / 2350 | 3540 / 3179 / 13904 | 12.7 |
| dracula/experto | 500 | 166 | 12889 / 10380 / 18970 | 42624 / 37400 / 189594 | 35.2 |
| dracula/medio | 500 | 166 | 7036 / 6340 / 10050 | 23250 / 22000 / 38693 | 10.7 |
| dracula/novato | 500 | 166 | 3166 / 1810 / 6300 | 10460 / 11000 / 24101 | 10.9 |
| kernel_panic/azar | 500 | 165 | 1500 / 870 / 4110 | 5524 / 4636 / 24956 | 13.0 |
| kernel_panic/experto | 500 | 144 | 12023 / 10430 / 19865 | 55179 / 49358 / 129904 | 26.7 |
| kernel_panic/medio | 500 | 164 | 7445 / 7170 / 10495 | 26130 / 23006 / 66553 | 11.3 |
| kernel_panic/novato | 500 | 166 | 3206 / 2160 / 6680 | 10785 / 11110 / 22427 | 10.7 |
| nautilus/azar | 500 | 166 | 2528 / 1260 / 7600 | 8934 / 5038 / 45384 | 13.2 |
| nautilus/experto | 500 | 160 | 15145 / 12040 / 29880 | 58466 / 53101 / 150088 | 27.9 |
| nautilus/medio | 500 | 166 | 8635 / 8020 / 12350 | 28901 / 28237 / 48931 | 13.9 |
| nautilus/novato | 500 | 166 | 3872 / 2690 / 7070 | 12880 / 13310 / 36927 | 10.9 |

## alicia/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6607 s de juego en 426 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 96%, outlane_der 3%.
- Se perdió con kickback listo: 94% de las bolas.
- Bolas salvadas: 409, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 150 | 1362 | 20.9% |
| 250 | 671 | 17.1% |
| 1500 | 103 | 15.8% |
| 100 | 1393 | 14.2% |
| 5000 | 22 | 11.2% |
| 300 | 336 | 10.3% |
| 1000 | 82 | 8.4% |
| 50 | 200 | 1.0% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.82 por bola
- `SKILL SHOT: AL CARRIL`: 0.63 por bola
- `BONUS ### X#`: 0.49 por bola
- `BOLA #`: 0.42 por bola
- `GRANDE`: 0.40 por bola
- `BONUS ## X#`: 0.35 por bola
- `CHICA`: 0.21 por bola
- `NAIPES COMPLETOS`: 0.16 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `¡KICKBACK!`: 0.06 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/azar](base2/heat_alicia_azar.png)

## alicia/experto

- Bolas: 500 en 153 partidas (1 proceso(s), velocidad x1.0, 17306 s de juego en 984 s reales).
- Por dónde se pierde: outlane_izq 7%, centro 62%, outlane_der 31%.
- Se perdió con kickback listo: 71% de las bolas.
- Bolas salvadas: 143, TILT: 0, bolas trabadas: 1, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 710 | 45.8% |
| 250 | 4967 | 16.0% |
| 300 | 2213 | 8.6% |
| 1500 | 386 | 7.5% |
| 100 | 5710 | 7.4% |
| 1000 | 556 | 7.2% |
| 150 | 2938 | 5.7% |
| 10 | 6240 | 0.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT: AL CARRIL`: 1.36 por bola
- `SKILL SHOT ####`: 1.36 por bola
- `NAIPES COMPLETOS`: 1.11 por bola
- `GRANDE`: 0.88 por bola
- `CHICA`: 0.75 por bola
- `BONUS #### X#`: 0.66 por bola
- `BONUS ### X#`: 0.33 por bola
- `LOCK ENCENDIDO`: 0.31 por bola
- `BOLA #`: 0.31 por bola
- `¡KICKBACK!`: 0.29 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/experto](base2/heat_alicia_experto.png)

## alicia/medio

- Bolas: 500 en 165 partidas (1 proceso(s), velocidad x1.0, 7038 s de juego en 505 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 97%, outlane_der 3%.
- Se perdió con kickback listo: 91% de las bolas.
- Bolas salvadas: 425, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 678 | 77.8% |
| 1500 | 122 | 4.2% |
| 250 | 688 | 3.9% |
| 150 | 1094 | 3.8% |
| 300 | 546 | 3.8% |
| 100 | 1512 | 3.5% |
| 1000 | 104 | 2.4% |
| 50 | 330 | 0.4% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT: AL CARRIL`: 1.32 por bola
- `SKILL SHOT ####`: 1.32 por bola
- `¡BOLA SALVADA!`: 0.85 por bola
- `BONUS ### X#`: 0.48 por bola
- `BONUS #### X#`: 0.47 por bola
- `CHICA`: 0.41 por bola
- `BOLA #`: 0.34 por bola
- `GRANDE`: 0.29 por bola
- `NAIPES COMPLETOS`: 0.21 por bola
- `¡KICKBACK!`: 0.09 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/medio](base2/heat_alicia_medio.png)

## alicia/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5417 s de juego en 413 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 482, TILT: 0, bolas trabadas: 4, rescates por escape: 0, máximo de bolas a la vez: 1.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 260 | 67.4% |
| 150 | 1328 | 10.3% |
| 1500 | 105 | 8.2% |
| 100 | 937 | 4.9% |
| 1000 | 80 | 4.1% |
| 300 | 207 | 3.2% |
| 250 | 116 | 1.5% |
| 50 | 100 | 0.3% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.96 por bola
- `BONUS ### X#`: 0.63 por bola
- `SKILL SHOT ####`: 0.52 por bola
- `SKILL SHOT: AL CARRIL`: 0.52 por bola
- `BOLA #`: 0.41 por bola
- `GRANDE`: 0.30 por bola
- `BONUS ## X#`: 0.16 por bola
- `NAIPES COMPLETOS`: 0.16 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `CHICA`: 0.10 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor alicia/novato](base2/heat_alicia_novato.png)

## dracula/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6375 s de juego en 546 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 98%, outlane_der 2%.
- Se perdió con kickback listo: 93% de las bolas.
- Bolas salvadas: 378, TILT: 0, bolas trabadas: 7, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 250 | 966 | 45.1% |
| 100 | 861 | 16.1% |
| 300 | 244 | 13.7% |
| 5000 | 13 | 12.1% |
| 150 | 182 | 5.1% |
| 50 | 411 | 3.8% |
| 500 | 20 | 1.9% |
| 10 | 807 | 1.5% |

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

![mapa de calor dracula/azar](base2/heat_dracula_azar.png)

## dracula/experto

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 17620 s de juego en 1288 s reales).
- Por dónde se pierde: outlane_izq 4%, centro 68%, outlane_der 27%.
- Se perdió con kickback listo: 74% de las bolas.
- Bolas salvadas: 142, TILT: 0, bolas trabadas: 20, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 758 | 58.8% |
| 250 | 5637 | 21.9% |
| 100 | 4172 | 6.5% |
| 300 | 1209 | 5.6% |
| 150 | 875 | 2.0% |
| 1000 | 101 | 1.6% |
| 50 | 2020 | 1.6% |
| 500 | 126 | 1.0% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.39 por bola
- `SKILL SHOT: AL CARRIL`: 1.39 por bola
- `BONUS #### X#`: 0.57 por bola
- `BONUS ### X#`: 0.43 por bola
- `BOLA #`: 0.33 por bola
- `¡BOLA SALVADA!`: 0.28 por bola
- `¡KICKBACK!`: 0.26 por bola
- `CARFAX #/#`: 0.20 por bola
- `LOCK ENCENDIDO`: 0.14 por bola
- `¡JACKPOT!  ####`: 0.13 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/experto](base2/heat_dracula_experto.png)

## dracula/medio

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5354 s de juego en 439 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 98%, outlane_der 2%.
- Se perdió con kickback listo: 99% de las bolas.
- Bolas salvadas: 465, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 665 | 94.5% |
| 250 | 433 | 3.1% |
| 300 | 105 | 0.9% |
| 100 | 293 | 0.8% |
| 50 | 175 | 0.2% |
| 150 | 50 | 0.2% |
| 10 | 404 | 0.1% |
| 500 | 5 | 0.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.33 por bola
- `SKILL SHOT: AL CARRIL`: 1.33 por bola
- `¡BOLA SALVADA!`: 0.93 por bola
- `BONUS ### X#`: 0.46 por bola
- `BONUS #### X#`: 0.45 por bola
- `BOLA #`: 0.38 por bola
- `BONUS ## X#`: 0.01 por bola
- `¡KICKBACK!`: 0.01 por bola
- `CARFAX #/#`: 0.01 por bola
- `BOLA ENCERRADA`: 0.00 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/medio](base2/heat_dracula_medio.png)

## dracula/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5435 s de juego en 438 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 100%, outlane_der 0%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 488, TILT: 0, bolas trabadas: 12, rescates por escape: 0, máximo de bolas a la vez: 2.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 267 | 84.3% |
| 250 | 306 | 4.8% |
| 100 | 603 | 3.8% |
| 500 | 64 | 2.0% |
| 150 | 191 | 1.8% |
| 300 | 84 | 1.6% |
| 1000 | 13 | 0.8% |
| 50 | 201 | 0.6% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.98 por bola
- `BONUS ### X#`: 0.54 por bola
- `SKILL SHOT ####`: 0.53 por bola
- `SKILL SHOT: AL CARRIL`: 0.53 por bola
- `BOLA #`: 0.41 por bola
- `BONUS ## X#`: 0.23 por bola
- `CARFAX #/#`: 0.14 por bola
- `BONUS #### X#`: 0.07 por bola
- `BONUS # X#`: 0.05 por bola
- `BOLA DESTRABADA`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor dracula/novato](base2/heat_dracula_novato.png)

## kernel_panic/azar

- Bolas: 500 en 165 partidas (1 proceso(s), velocidad x1.0, 6490 s de juego en 426 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 92%, outlane_der 8%.
- Se perdió con kickback listo: 89% de las bolas.
- Bolas salvadas: 390, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 1500 | 97 | 19.4% |
| 1000 | 135 | 18.0% |
| 100 | 1284 | 17.1% |
| 225 | 454 | 13.6% |
| 5000 | 14 | 9.3% |
| 160 | 351 | 7.5% |
| 500 | 102 | 6.8% |
| 140 | 173 | 3.2% |

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

![mapa de calor kernel_panic/azar](base2/heat_kernel_panic_azar.png)

## kernel_panic/experto

- Bolas: 500 en 144 partidas (1 proceso(s), velocidad x1.0, 13344 s de juego en 1046 s reales).
- Por dónde se pierde: outlane_izq 26%, centro 40%, outlane_der 34%.
- Se perdió con kickback listo: 43% de las bolas.
- Bolas salvadas: 163, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 663 | 55.1% |
| 1000 | 772 | 12.8% |
| 100 | 5366 | 8.9% |
| 225 | 2201 | 8.2% |
| 1500 | 233 | 5.8% |
| 500 | 386 | 3.2% |
| 160 | 995 | 2.6% |
| 140 | 430 | 1.0% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `BONUS X#`: 1.68 por bola
- `SKILL SHOT ####`: 1.32 por bola
- `SKILL SHOT: AL CARRIL`: 1.32 por bola
- `BONUS #### X#`: 0.60 por bola
- `¡KICKBACK!`: 0.57 por bola
- `PROCESO #/#`: 0.45 por bola
- `FORK() LISTO: AL SAUCER`: 0.40 por bola
- `BONUS ### X#`: 0.40 por bola
- `¡BOLA SALVADA!`: 0.33 por bola
- `BOLA #`: 0.29 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/experto](base2/heat_kernel_panic_experto.png)

## kernel_panic/medio

- Bolas: 500 en 164 partidas (1 proceso(s), velocidad x1.0, 5657 s de juego en 384 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 95%, outlane_der 4%.
- Se perdió con kickback listo: 94% de las bolas.
- Bolas salvadas: 441, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 655 | 88.0% |
| 1000 | 122 | 3.3% |
| 225 | 366 | 2.2% |
| 1500 | 53 | 2.1% |
| 100 | 682 | 1.8% |
| 160 | 218 | 0.9% |
| 500 | 61 | 0.8% |
| 140 | 68 | 0.3% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.31 por bola
- `SKILL SHOT: AL CARRIL`: 1.31 por bola
- `¡BOLA SALVADA!`: 0.88 por bola
- `BONUS ### X#`: 0.46 por bola
- `BONUS #### X#`: 0.46 por bola
- `BOLA #`: 0.38 por bola
- `BONUS X#`: 0.34 por bola
- `PROCESO #/#`: 0.12 por bola
- `FORK() LISTO: AL SAUCER`: 0.10 por bola
- `¡KICKBACK!`: 0.06 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/medio](base2/heat_kernel_panic_medio.png)

## kernel_panic/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5332 s de juego en 354 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 98% de las bolas.
- Bolas salvadas: 493, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 261 | 81.4% |
| 1500 | 52 | 4.9% |
| 100 | 489 | 3.1% |
| 500 | 92 | 2.9% |
| 160 | 210 | 2.1% |
| 225 | 135 | 1.9% |
| 1000 | 30 | 1.9% |
| 140 | 98 | 0.9% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.99 por bola
- `BONUS ### X#`: 0.56 por bola
- `SKILL SHOT ####`: 0.52 por bola
- `SKILL SHOT: AL CARRIL`: 0.52 por bola
- `BOLA #`: 0.41 por bola
- `BONUS ## X#`: 0.20 por bola
- `BONUS X#`: 0.16 por bola
- `PROCESO #/#`: 0.13 por bola
- `BONUS #### X#`: 0.06 por bola
- `BONUS # X#`: 0.06 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor kernel_panic/novato](base2/heat_kernel_panic_novato.png)

## nautilus/azar

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6594 s de juego en 636 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 96%, outlane_der 3%.
- Se perdió con kickback listo: 88% de las bolas.
- Bolas salvadas: 391, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 90 | 35.6% |
| 360 | 814 | 23.2% |
| 150 | 1028 | 12.2% |
| 100 | 1461 | 11.6% |
| 250 | 455 | 9.0% |
| 480 | 164 | 6.2% |
| 50 | 355 | 1.4% |
| 10 | 1060 | 0.8% |

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

![mapa de calor nautilus/azar](base2/heat_nautilus_azar.png)

## nautilus/experto

- Bolas: 500 en 160 partidas (1 proceso(s), velocidad x1.0, 13952 s de juego en 1468 s reales).
- Por dónde se pierde: outlane_izq 7%, centro 63%, outlane_der 30%.
- Se perdió con kickback listo: 55% de las bolas.
- Bolas salvadas: 114, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 954 | 63.0% |
| 150 | 5086 | 10.1% |
| 100 | 6820 | 9.0% |
| 360 | 1325 | 6.3% |
| 480 | 810 | 5.1% |
| 250 | 1333 | 4.4% |
| 50 | 2010 | 1.3% |
| 10 | 5816 | 0.8% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.22 por bola
- `SKILL SHOT: AL CARRIL`: 1.22 por bola
- `¡KRAKEN ACTIVO!`: 0.72 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.66 por bola
- `BONUS #### X#`: 0.56 por bola
- `¡KICKBACK!`: 0.45 por bola
- `BONUS ### X#`: 0.44 por bola
- `BOLA #`: 0.32 por bola
- `¡BOLA SALVADA!`: 0.23 por bola
- `¡BOLA EXTRA!`: 0.04 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/experto](base2/heat_nautilus_experto.png)

## nautilus/medio

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 6945 s de juego en 708 s reales).
- Por dónde se pierde: outlane_izq 1%, centro 95%, outlane_der 3%.
- Se perdió con kickback listo: 89% de las bolas.
- Bolas salvadas: 408, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 668 | 77.4% |
| 360 | 1409 | 11.7% |
| 100 | 1303 | 3.0% |
| 150 | 830 | 2.9% |
| 250 | 426 | 2.5% |
| 480 | 132 | 1.5% |
| 50 | 720 | 0.8% |
| 10 | 969 | 0.2% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `SKILL SHOT ####`: 1.25 por bola
- `SKILL SHOT: AL CARRIL`: 1.25 por bola
- `¡BOLA SALVADA!`: 0.82 por bola
- `BONUS ### X#`: 0.51 por bola
- `BONUS #### X#`: 0.47 por bola
- `BOLA #`: 0.33 por bola
- `¡KRAKEN ACTIVO!`: 0.12 por bola
- `¡KICKBACK!`: 0.11 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.09 por bola
- `BONUS ## X#`: 0.02 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/medio](base2/heat_nautilus_medio.png)

## nautilus/novato

- Bolas: 500 en 166 partidas (1 proceso(s), velocidad x1.0, 5474 s de juego en 529 s reales).
- Por dónde se pierde: outlane_izq 0%, centro 99%, outlane_der 1%.
- Se perdió con kickback listo: 92% de las bolas.
- Bolas salvadas: 476, TILT: 0, bolas trabadas: 0, rescates por escape: 0, máximo de bolas a la vez: 3.

**Fuentes de puntos** (valor de cada aviso de puntaje; solo lo que pasó por `GameState.scored`, sin el bonus de fin de bola):

| Puntos por golpe | Veces | Aporte al total |
|---:|---:|---:|
| 5000 | 289 | 74.6% |
| 360 | 686 | 12.8% |
| 250 | 308 | 4.0% |
| 100 | 683 | 3.5% |
| 150 | 390 | 3.0% |
| 480 | 60 | 1.5% |
| 50 | 175 | 0.5% |
| 10 | 256 | 0.1% |

**Avisos del juego por bola** (modos, misiones, multibola, jackpot; los dígitos se agrupan en `#`):

- `¡BOLA SALVADA!`: 0.95 por bola
- `BONUS ### X#`: 0.57 por bola
- `SKILL SHOT ####`: 0.52 por bola
- `SKILL SHOT: AL CARRIL`: 0.52 por bola
- `BONUS ## X#`: 0.35 por bola
- `BOLA #`: 0.33 por bola
- `BONUS #### X#`: 0.08 por bola
- `¡KICKBACK!`: 0.08 por bola
- `¡KRAKEN ACTIVO!`: 0.08 por bola
- `¡JACKPOT!  #### M  BONUS X#`: 0.05 por bola

Mapa de calor (por dónde anda la bola, escala logarítmica):

![mapa de calor nautilus/novato](base2/heat_nautilus_novato.png)

