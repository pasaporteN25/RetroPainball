# Diseño de mesas: palancas, progresión y checklist

*F1d de [PLAN_BETA.md](PLAN_BETA.md). Escrito el 24 de noviembre de 2026 con los informes de
playtesting [base](playtest/base.md), [base2](playtest/base2.md) y [skill2000](playtest/skill2000.md).*

Esta guía sirve para dos cosas: **ajustar las cuatro mesas que ya existen** y **diseñar la quinta**
(y las que sigan) sabiendo de antemano qué número mover y qué medir.

Una regla de proyecto que atraviesa todo el documento: **el juego no tiene niveles de dificultad.**
No hay selector, ni modo Torneo, ni dificultad elegible por mesa. La complejidad crece **mesa a mesa**
en el orden del carrusel (Kernel Panic → 20.000 Leguas → Drácula → Alicia → la que siga): cada mesa
nueva tiene más reglas, más objetivos encadenados y más multibolas que la anterior. Lo que **no** crece
de una mesa a otra es lo injusto: cuánto dura una bola tiene que ser parejo en todas (ver §4).

## 0. Cómo leer los números

- Todos los números salen del runner `tools/playtest/` con **500 bolas por mesa y bot**, `--fixed-fps 60`
  (determinista). Los niveles `novato`, `medio`, `experto` y `azar` son **habilidad del bot**, no del juego.
- **Las metas se miden con el bot medio**; el novato y el experto marcan los extremos.
- Limitaciones del bot que hay que tener presentes (ver [tools/playtest/README.md](../tools/playtest/README.md)):
  - **No lee las reglas**: no apunta a lo que está encendido. Medio y experto se diferencian por reacción,
    puntería del golpe, retención y nudge. Por eso todo lo que dependa de "tirar a un objetivo" (llegar al
    lock, al saucer, al jackpot) **está subestimado**; el experto humano llega más.
  - El informe muestra solo las **8 fuentes de puntos** y los **10 avisos** más frecuentes. Si un aviso
    (por ejemplo `¡FORK()!  MULTIBOLA`) no aparece, es que salió menos que el décimo, no que no salió.
  - Los avisos se cuentan **por bola**, no por partida. Para estimar "% de partidas que llegan a X" hoy
    hay que multiplicar por ~3,1 bolas por partida, y eso da un **techo** (dos multibolas en la misma
    partida cuentan doble). Ver la mejora pendiente en §5.
- Para medir un cambio: correr **antes y después con la misma semilla y el mismo `-x`**, y comparar:

```bash
./tools/playtest.sh -t all -b all -n 500 -o build/playtest/antes
# ...aplicar el cambio en los .tres o en la escena...
./tools/playtest.sh -t all -b all -n 500 -o build/playtest/despues -r
godot --headless --path . -s tools/playtest/report.gd -- dir=build/playtest/despues base=build/playtest/antes
```

Un cambio, una corrida. Si se tocan dos palancas a la vez no se sabe cuál movió qué.

## 1. Dónde están hoy las mesas (informe skill2000, el vigente en `master`)

Bot medio, contra las metas de F1c:

| Métrica (bot medio) | Meta F1c | Kernel Panic | 20.000 Leguas | Drácula | Alicia |
|---|---|---:|---:|---:|---:|
| Segundos por bola | 45–90 | **11,3** | **13,9** | **10,7** | **12,0** |
| Segundos por partida | — | 34 | 42 | 32 | 36 |
| Bolas perdidas por outlanes | 35–50 % | **5 %** | **4 %** | **2 %** | **1 %** |
| Bolas que usaron el salvabolas | — | 88 % | 82 % | 93 % | 92 % |
| Mayor fuente de puntos | < 35 % | **74 %** (skill shot) | **51 %** (skill shot) | **87 %** (skill shot) | **67 %** (skill shot) |
| Experto ÷ novato (puntos por partida) | 4×–10× | 6,8× | 5,9× | 5,6× | 5,5× |

Bot experto, para ver la otra punta:

| Métrica (bot experto) | Kernel Panic | 20.000 Leguas | Drácula | Alicia |
|---|---:|---:|---:|---:|
| Segundos por bola | 26,7 | 27,9 | 35,2 | 32,1 |
| Outlane izq. / der. | 26 % / 34 % | 7 % / 30 % | 4 % / 27 % | 6 % / 33 % |
| Diferencia izq.–der. (meta < 10 puntos) | 8 | **23** | **23** | **27** |
| Mayor fuente de puntos | 33 % (skill shot) | 30 % (jackpot) | 32 % (blancos de 250) | 26 % (skill shot) |
| Avisos de modo por bola | `FORK() LISTO` 0,40 | `¡KRAKEN ACTIVO!` 0,72, jackpot 0,66 | `LOCK ENCENDIDO` 0,14, jackpot 0,13 | `NAIPES COMPLETOS` 1,04, `LOCK ENCENDIDO` 0,31 |

Lectura en una línea: **la escala de habilidad está bien** (el experto hace 5,5–6,8 veces lo del novato),
**pero la bola dura cuatro veces menos de lo que debería y se va casi toda por el centro**, y al
experto lo castiga el outlane derecho porque el kickback está solo a la izquierda.

## 2. Palancas de ajuste

Cada palanca dice dónde vive, cuánto vale hoy, en qué sentido mueve y qué se midió. Donde dice
**medido** hay una corrida A/B detrás; donde dice **estimado** es una cuenta o una hipótesis que hay
que confirmar con el runner antes de darla por buena.

Las reglas del repo valen acá: los números de balance van en Resources (`resources/rules/*.tres`,
`resources/table_physics.tres`) y la geometría en las escenas. Las palancas que hoy son constantes en el
código (marcadas **en código**) conviene pasarlas a un Resource antes de usarlas para afinar.

### 2.1 Cuánto dura la bola

#### Hueco central y flippers

Es **la palanca que más falta mover**: con el bot medio, entre el 95 % y el 99 % de las bolas se van por el centro.

| Qué | Dónde | Hoy |
|---|---|---|
| Largo del flipper | `scripts/table/flipper.gd` → `length` (export, por escena) | 110 px |
| Radio de la punta | `flipper.gd` → `tip_radius` | 7 px |
| Ángulo en reposo / arriba | `flipper.gd` → `rest_angle_deg` / `up_angle_deg` | 30° / 28° |
| Posición de los bujes | `scenes/table_base.tscn` → `LeftFlipper` / `RightFlipper` | (214, 1250) y (458, 1250) |
| Velocidad de subida / bajada | `table_physics.tres` → `flipper_up_speed` / `flipper_down_speed` | 26 / 16 rad/s |
| Rozamiento del flipper | `table_physics.tres` → `flipper_friction` | 0,8 |

**Cuenta (estimado):** con los bujes a 244 px de distancia, 110 px de largo y 30° de caída, las puntas en
reposo quedan a 53 px una de otra; menos las dos puntas de 7 px quedan **39 px libres** para una bola de
**32 px** (radio 16). Sobran 7 px.

- **Cada +1 px de largo cierra ~1,7 px el hueco** (cos 30° por flipper). Con +4 px (114) quedan ~32 px:
  la bola apenas pasa en reposo. Con +5 px ya no pasa quieta. Es una palanca muy sensible: moverla de a 1 px.
- Bajar el ángulo de reposo cierra el hueco y además empina el flipper (la bola rueda más rápido a la
  punta): más difícil atrapar. Subirlo hace lo contrario.
- **Más largo no es solo más fácil**: el flipper llega más lejos, pero el punto dulce del tiro se corre y
  los blancos que hoy se alcanzan con la punta cambian de ángulo. Después de tocarlo, revisar que los tiros
  de las misiones (lock, saucer, rampas) sigan saliendo.
- `flipper_up_speed` más alto = tiros más fuertes y menos tiempo para que la bola pase por debajo; más bajo
  = flipper "blando". Es más sensación (F7) que balance: tocarlo después del teléfono real.
- `flipper_friction` alto ayuda a retener la bola (el *cradle*); el bot medio a veces retiene y el novato nunca.

**Qué mirar:** `centro %` y segundos por bola del medio; que el novato no pase de 45 s (si la bola se
traba entre flippers, el hueco quedó demasiado chico).

#### Outlanes y postes

| Qué | Dónde | Hoy |
|---|---|---|
| Ancho del outlane | `table_base.tscn` → pared exterior x=16 y guía del inlane `LeftInlane` / `RightInlane` | ~48 px libres (x 16→64) para una bola de 32 |
| Poste entre outlane e inlane | punta de `LeftInlane` (82, 917) y de `RightInlane` (590, 917) | simétricos |
| Deflectores sobre los outlanes | `LeftDeflector` / `RightDeflector` | simétricos |

- Acercar el poste hacia la pared (o subir la punta) achica la boca del outlane y manda más bolas al inlane,
  que lleva al flipper. Mover el poste **hacia el centro** hace lo contrario.
- La regla de oro: **los outlanes deben llevarse 35–50 % de las bolas**, porque perder por el costado se
  siente "mala suerte que pude evitar con nudge" y perder por el centro se siente "no llegué". Hoy pasa al
  revés: con el medio los outlanes se llevan 1–5 %, y achicarlos no arregla nada. **Primero cerrar el centro,
  después medir outlanes.**
- Para el experto ya hay datos: pierde 27–34 % por el outlane derecho y 4–7 % por el izquierdo en
  Leguas, Drácula y Alicia. La asimetría no es de geometría (es simétrica): es el kickback (abajo).

#### Kickback

| Qué | Dónde | Hoy |
|---|---|---|
| Lado | `scripts/table/kickback.gd` → `outlane_path` | solo **izquierdo** |
| Cargas | `GameState.kickback_ready` (**en código**) | 1 por bola, se rearma al perder la bola |
| Salida | `kickback.gd` → `pop_position`, `pop_velocity` | (150, 860), (230, −850) |

- **Medido:** el kickback izquierdo baja el outlane izquierdo del experto a 4–7 % mientras el derecho queda en
  27–34 %: una diferencia de **23–27 puntos** (meta < 10). Kernel Panic es la excepción (26 % / 34 %, 8 puntos),
  porque su layout manda más bolas al lado izquierdo.
- Con el medio, la bola se perdió con el kickback **todavía listo** en el 89–99 % de los casos: casi nunca
  llega a usarlo porque se va por el centro. Es una palanca que solo importa al experto (y al jugador real).
- Para emparejar lados hay tres caminos, de menor a mayor cambio: (1) achicar solo el outlane derecho
  (mover el poste derecho unos píxeles hacia la pared); (2) un kickback por lado con una carga compartida;
  (3) cargas que se ganan (por ejemplo, completar los carriles de retorno rearma el kickback) — esto es
  **en código** y además es una herramienta de complejidad para mesas nuevas (§3).
- Una carga más por bola equivale, a lo sumo, a una bola salvada más por cada outlane que se lleve la bola.
  Con 30 % de bolas perdidas por ese outlane, rinde como mucho un 30 % más de vida en ese lado.

#### Salvabolas

| Qué | Dónde | Hoy |
|---|---|---|
| Duración | `scripts/main.gd` → `BALL_SAVE_TIME` (**en código**) | 8 s desde que sale cada bola nueva |
| Tope | `main.gd` → `_serving_saved` | **una salvada por bola** (desde el commit 2b85523) |

- **Medido, es la palanca que más movió:** sin tope, una bola que se perdía antes de 8 s se salvaba una y otra
  vez. De `base` (sin tope) a `base2` (con tope):

  | Bot | Segundos por bola sin tope | Con tope | Bolas salvadas (500 bolas) |
  |---|---:|---:|---|
  | Novato | 137–222 s | 10,8–10,9 s | Drácula 4718 → 488; Leguas 4295 → 476 |
  | Medio | 28–45 s | 10,7–14,1 s | 333–487 → 408–465 |
  | Experto | 30–36 s | 27–35 s | 156–262 → 114–163 |

  El tope casi no cambia al experto y deja al novato y al medio en la realidad. Quedó bien; no volver atrás.
- Hoy el **82–93 % de las bolas del medio** usa su salvada: la mayoría se pierde dentro de los primeros 8 s.
  Eso dice que la primera bajada a los flippers (la bola de saque baja siempre por el costado izquierdo,
  ver [mesas/ALICIA.md](mesas/ALICIA.md)) es el momento más peligroso de cada bola.
- Alargar el salvabolas (10–12 s) **sube la duración media muy poco** con tope de una salvada: solo rescata las
  bolas que se pierden entre 8 y 12 s. Acortarlo (5–6 s) castiga sobre todo al novato. Es una palanca fina,
  no gruesa. Para usarla de verdad, pasarla a `TableRules` (un valor por mesa).
- Ojo: cada saque salvado **vuelve a armar el skill shot** (el medio cobra 1,31 skill shots por bola). Si se
  cambia el salvabolas, mirar también la fuente de puntos del skill shot.

#### Gravedad

| Qué | Dónde | Hoy |
|---|---|---|
| Gravedad | `table_physics.tres` → `gravity` | 1600 px/s² |
| Velocidad máxima de la bola | `table_physics.tres` → `ball_max_speed` | 4200 px/s |

- Los tiempos de caída escalan con 1/√g: **+10 % de gravedad ≈ 5 % menos de tiempo para reaccionar**, y la
  bola sube menos por las rampas y órbitas (los tiros largos fallan más). −10 % hace todo más lento y "flotante".
- Es una palanca **global** (todas las mesas comparten `table_physics.tres`) y de **sensación**: no se usa para
  diferenciar mesas. Se decide con el teléfono en la mano (F7, G-01) y después se vuelve a correr todo.
- **Estimado:** el bot reacciona a ~70 / 110 / 180 ms (experto / medio / novato). Un 5 % menos de tiempo pega
  más al novato, que ya está al límite.

#### Slingshots y bumpers

| Qué | Dónde | Hoy |
|---|---|---|
| Rebote / patada del slingshot | `table_physics.tres` → `slingshot_bounce`, `slingshot_kick_speed` | 0,25 / 1000 px/s |
| Patada del bumper | `bumper_kick_speed`, `bumper_tangent_keep` | 1300 px/s / 0,5 |

- Los slingshots están justo arriba de los flippers: **más patada = bola más rápida y más caótica en la zona de
  flippers**, más pérdidas por el centro y por el outlane del lado contrario. Menos patada = la bola llega mansa
  a los flippers y se puede atrapar. Hoy, con el centro llevándose casi todo, **bajar `slingshot_kick_speed`
  (1000 → 850–900) es candidato a segunda corrida**, después del hueco central.
- Los bumpers mueven más el puntaje que la vida de la bola: más patada = más golpes de 100 por segundo y la bola
  baja más rápido. Si los 100 de los bumpers pasan del 35 % del total, la mesa es "pinball de suerte".

#### Nudge y TILT

`main.gd` → `nudge_speed` (240 px/s) y `scripts/table/tilt.gd` (`nudge_heat` 0,35, `tilt_heat` 1,0,
`decay_per_second` 0,3). En las tres corridas el TILT dio **0** con todos los bots: el experto usa el nudge con
moderación. Es una palanca de jugador experto (salvar outlanes empujando); no tocarla hasta tener datos de
personas (F8).

### 2.2 Cuánto tarda en pasar algo

#### Largo de las misiones

Todos estos números viven en `resources/rules/<mesa>.tres` (`TableRules`):

| Mesa | Misión | Palanca | Hoy |
|---|---|---|---|
| Kernel Panic | Procesos para `fork()` | `fork_processes_needed` | 2 |
| Kernel Panic | Vueltas del spinner para `sudo` | `sudo_laps` | 12 |
| 20.000 Leguas | Sonares para activar el kraken | `sonar_count` | 3 |
| 20.000 Leguas | Tiempo entre compuertas de la corriente | `current_travel_seconds` | 3,0 s |
| Drácula | Encierros para la Medianoche | `locks_for_midnight` | 2 |
| Drácula | Vueltas Carfax hasta cerrar el ciclo | `carfax_stages` (cantidad de etapas) | 3 |
| Drácula | Tiempo entre compuertas Carfax | `carfax_travel_seconds` | 3,0 s |
| Alicia | Encierros para Té Loco | `locks_for_tea_party` | 2 |
| Alicia | Gato visible / oculto | `cheshire_visible_seconds` / `cheshire_hidden_seconds` | 4 / 3 s |

- Cada paso más en una cadena **multiplica**, no suma: si un paso sale con probabilidad *p* por bola, una
  cadena de *n* pasos sale aproximadamente con *p*ⁿ. Por eso pasar de 2 a 3 encierros no es "50 % más largo":
  con *p* = 0,3 baja la llegada de 9 % a 2,7 %.
- **Medido (experto):** donde la cadena es corta y no pide puntería fina, se llega; donde termina en un tiro
  preciso, no. 20.000 Leguas (3 sonares y un golpe al kraken) da 0,72 kraken activo y 0,66 jackpots por bola.
  Alicia completa los naipes 1,04 veces por bola pero el lock pide además tamaño CHICA y la madriguera:
  `LOCK ENCENDIDO` 0,31 por bola y Té Loco no entra en los 10 avisos. Kernel Panic llega a `FORK() LISTO`
  0,40 por bola, pero la multibola no entra en los 10 avisos: el cuello de botella es el tiro al saucer.
- La palanca más barata para acortar una misión **no es bajar el número**, es **guardar el progreso entre bolas**
  (como los sonares y la profundidad de 20.000 Leguas). Hace que la misión se termine en la partida aunque cada
  bola sea corta. Hoy Drácula y Alicia pierden el progreso del banco al perder la bola.
- Las ventanas de tiempo (`*_travel_seconds`, el gato) son palancas de habilidad: más cortas premian al que
  sabe el tiro y casi no afectan al novato (que no llega de todas formas).

#### Tiempo de los modos

- Hoy **ningún modo tiene reloj**: Medianoche, Té Loco y `fork()` duran mientras quede más de una bola, y
  terminan solos al quedar una. Lo que dura un modo depende de la habilidad para mantener 3 bolas, no de un
  número.
- Herramientas posibles (todas **en código**, para una mesa nueva o un ajuste posterior):
  - **Salvabolas de multibola** (por ejemplo, 10 s al empezar el modo): es lo que más alarga los modos para el
    jugador medio sin regalarle nada al experto. Sería un valor de `TableRules` por mesa.
  - **Modo con reloj** (30–45 s) en vez de "hasta que quede una bola": da un modo que se puede jugar con una
    sola bola, y es una forma de sumar modos sin sumar multibolas.
  - **Reloj que se alarga** con cada tiro bueno (como el gato de Cheshire, `cheshire_extend_seconds`).

#### Cuántos blancos hacen falta para la multibola

| Mesa | Camino a la multibola hoy | Pasos |
|---|---|---|
| Kernel Panic | 2 procesos (banco de blancos o carriles completos) → saucer | 3 |
| 20.000 Leguas | 3 sonares → kraken (con una sola bola en juego) | 4 golpes, sin orden |
| Drácula | 3 murciélagos → lock → ataúd, dos veces | 8 |
| Alicia | 4 naipes → lock → CHICA → madriguera, dos veces | 12 |

Meta del medio: **30–50 % de las partidas llegan a la multibola** (novato 5–15 %, experto más de 70 %). Hoy el
medio está muy lejos: en Kernel Panic, `SEGFAULT: FIN DE LA MULTIBOLA` da 0,03 por bola, o sea como mucho ~10 %
de las partidas, y en las otras tres mesas no aparece entre los avisos. Pero **la causa es que la bola dura
11–14 s**, no el largo del camino: con bolas de 45–90 s el mismo camino se recorre. Ajustar el largo de la
misión **después** de arreglar la duración de la bola.

### 2.3 Cuánto paga

#### Premio del skill shot

| Qué | Dónde | Hoy |
|---|---|---|
| Premio | `TableRules.skill_shot_award` | 2.000 (antes 5.000) |
| Ventana de potencia | `scripts/table/plunger.gd` → `skill_min` / `skill_max` | 0,70–0,90 |
| Tiempo para entrar al carril | `TableRules.skill_shot_seconds` | 5 s |

- **Medido (5.000 → 2.000, commit 642a026):**

  | Bot | Mayor fuente con 5.000 | Con 2.000 | Experto ÷ novato |
  |---|---|---|---|
  | Experto | 46–63 % | **26–33 %** (meta < 35 %) | 4,1–5,1× → 5,5–6,8× |
  | Medio | 77–95 % | 51–87 % | — |
  | Novato | 67–84 % | 45–68 % | — |

  Bajar el skill shot subió la escala de habilidad: el puntaje ahora sale más del juego en el tablero.
- El medio sigue dominado por el skill shot porque sus bolas duran 11 s: el saque es casi todo lo que hace.
  **No bajarlo más todavía**; cuando las bolas duren lo que tienen que durar, la proporción cae sola. Volver a
  medir entonces.
- Ensanchar la ventana (por ejemplo 0,65–0,92) lo hace más fácil para todos; estrecharla premia al que conoce el
  resorte. En los informes, cada skill shot armado se cobró (armados = cobrados con los tres bots): la dificultad
  está toda en la potencia, no en el carril. El novato lo cobra 0,52 veces por bola; el medio, 1,31.
- Dos efectos a corregir más adelante: el skill shot se rearma en el saque de una bola salvada, y el valor es el
  mismo en todas las mesas. Para una mesa nueva, conviene que el skill shot **avance algo de la misión** (un
  sonar, un naipe) en vez de pagar solo puntos: enseña el objetivo en el primer segundo.

#### Jackpots y premios de misión

- Regla de proporción: un jackpot debe valer **entre 2× y 4× lo que vale completar el paso anterior** de su
  cadena, y **ninguna pieza debe pasar del 35 % del total** con el experto. Hoy el jackpot de 20.000 Leguas (5.000)
  es el 30 % del experto: está en el borde. Si se le acorta la cadena, bajarle el premio.
- Los premios que suben el multiplicador (`raise_multiplier` en los `RuleStage`) pesan más de lo que dice la
  tabla de fuentes, porque el bonus de fin de bola no pasa por `GameState.scored`.

### 2.4 En qué orden tocar las palancas (para F1c)

1. **Hueco central** (largo o ángulo del flipper, de a 1 px o 1°) hasta que el medio pierda menos del 65 % por el
   centro. Es lo único que acerca los 11 s a los 45 s.
2. **Slingshots** (patada) si con el hueco solo no alcanza.
3. **Outlanes y kickback**: recién ahí medir outlanes (meta 35–50 %) y emparejar izquierda y derecha (< 10 puntos).
4. **Misiones y multibola**: con la bola durando 45–90 s, ver cuántas partidas llegan; ajustar largo o guardar
   progreso entre bolas.
5. **Puntajes**: skill shot y jackpots al final, porque dependen de todo lo anterior.

Las palancas de física son **globales** (`table_physics.tres` y `table_base.tscn`): un cambio ahí se mide en las
cuatro mesas a la vez. Lo que diferencia mesas va en las reglas y en el layout de cada escena.

## 3. Cómo sube la complejidad de mesa en mesa

No hay niveles de dificultad: **la mesa siguiente es la dificultad siguiente**. Pero "más compleja" no es "la
bola dura menos". Las metas de vida de la bola (§1 y §5) son **las mismas para todas las mesas**; lo que crece es
cuánto hay para aprender y encadenar.

### Lo que crece

| Mesa | Qué agregó respecto de la anterior |
|---|---|
| **Kernel Panic** | Lo clásico: bumpers, banco de blancos, carriles superiores, saucer. Multibola `fork()` con un solo requisito (2 procesos) y jackpot `sudo` dentro de la multibola |
| **20.000 Leguas** | Una misión con **progreso que se guarda entre bolas** (sonares y profundidad), dos tiros de habilidad con ventana de tiempo (corriente y cámara) y un jackpot que además abre la multibola |
| **Drácula** | **Lock clásico**: encerrar dos bolas para la multibola (cadena de 8 pasos), y una órbita con **etapas** (Carfax 1/3, 2/3, 3/3) que sube el multiplicador |
| **Alicia** | Un **estado que cambia las reglas** (tamaño: GRANDE dobla los naipes, CHICA es requisito del lock), un blanco que **aparece y desaparece** (gato) y una multibola que se gana por un camino condicionado (12 pasos) |

### Herramientas para la mesa siguiente (en orden de "cuánta complejidad suman")

1. **Más modos**: un modo con reloj (§2.2) además de la multibola, para que haya algo que hacer con una sola bola.
   Una mesa nueva debería tener **un modo más** que la anterior.
2. **Objetivos encadenados**: que completar A **encienda** B, en vez de que A y B paguen por separado. Cada mesa
   nueva suma **un eslabón** a su cadena principal, no tres: recordar que cada paso multiplica (*p*ⁿ).
3. **Estados que cambian las reglas** (como el tamaño de Alicia): la misma pieza paga o hace distinto según el
   estado. Es la complejidad más "barata" en piezas y la más rica para el jugador.
4. **Más multibolas o multibolas que se apilan**: una segunda multibola distinta, o un jackpot que sube de valor
   mientras dura (super jackpot), o volver a encender el lock durante la multibola.
5. **Piezas con tiempo** (blancos que aparecen, ventanas, compuertas): suman habilidad sin sumar reglas.
6. **Progreso entre bolas** (como los sonares): permite cadenas más largas sin que la mesa se vuelva imposible.
7. **Kickback que se gana** (§2.1) o salvabolas que se recarga con un objetivo: protección como premio, no como regalo.

### Lo que **no** se usa para subir la complejidad

- Achicar el hueco o los outlanes, subir la gravedad o acortar el salvabolas en la mesa nueva. Eso hace la mesa
  más cruel, no más rica, y rompe la paridad entre mesas (y la física es compartida).
- Cadenas de más de un eslabón nuevo por mesa: si el medio no llega nunca, el modo no existe para él.

## 4. Curva de progresión

Una partida de tres bolas, con bolas de 45–90 s, dura **2,5 a 5 minutos** para el jugador medio. Sobre eso:

### Primer minuto (la primera bola)

- **Algo se enciende en los primeros 10 s**: el skill shot o el primer blanco de la misión principal. Si el
  skill shot avanza la misión, mejor (§2.3).
- El salvabolas cubre el primer error (8 s, una vez). El jugador **no debería perder la primera bola antes de
  los 30 s** sin entender por qué.
- Al terminar el minuto, el jugador vio **qué es lo que hay que hacer** en la mesa: el primer paso de la cadena
  principal completo al menos una vez (un banco, los sonares, los murciélagos).
- **Hoy:** el medio pierde la bola a los 11–14 s y usa el salvabolas en el 82–93 % de las bolas; la partida
  entera del medio dura **32–42 s**. El primer minuto hoy es la partida completa. Es lo primero a arreglar.

### A los cinco minutos (fin de la primera partida)

- El jugador medio llegó **una vez al modo o la multibola** en una de cada dos o tres partidas (meta 30–50 %),
  y vio el jackpot en una de cada tres a seis (meta 15–35 %).
- Ganó un multiplicador o una bola extra al menos una vez.
- Ya tiene un récord para batir y sabe qué tiro le faltó.
- **Hoy:** el experto tarda 87–106 s por partida; el medio no llega a la multibola casi nunca (Kernel Panic ~10 %
  como techo, el resto fuera de los 10 avisos).

### A los veinte minutos (cuatro a seis partidas)

- El jugador aprendió **la jugada** de la mesa: el tiro que el experto repite y el novato no sabe (el kraken en
  20.000 Leguas, el saucer en Kernel Panic, el ataúd con LOCK en Drácula, CHICA + madriguera en Alicia).
  Su puntaje por partida tiene que **subir entre la primera y la quinta partida**: si no sube, la habilidad
  no importa (por eso la meta experto ÷ novato de 4×–10×; hoy 5,5–6,8×, bien).
- Llegó a la segunda capa: el jackpot dentro de la multibola, la tercera etapa de una cadena, la bola extra.
- Le queda algo sin ver: un modo, una etapa o un super jackpot que solo sale con la jugada dominada. Esa es la
  razón para volver, y la que lo empuja a **la mesa siguiente** del carrusel, que es más compleja.

## 5. Checklist de mesa nueva

Una mesa nueva no es jugable hasta que pasa todo esto. Se corre con **500 bolas por bot como mínimo**
(2.000 para el informe final de la mesa), las cuatro mesas existentes en la misma corrida para comparar:

```bash
./tools/playtest.sh -t all -b all -n 500 -o build/playtest/<mesa>-v1
```

### Integridad (cualquier bot, sin excepción)

- [ ] **0 bolas escapadas** de la mesa (`rescates por escape: 0`).
- [ ] **0 bolas trabadas sin rescate**. Las trabadas que rescata el detector se cuentan y se miran: si un bot
      pasa de ~5 por cada 500 bolas, hay un rincón que corregir en el layout (hoy Drácula experto da 20 y
      Alicia novato 4: revisar en F1c).
- [ ] TILT en 0 con los cuatro bots.
- [ ] `tests/headless/table_random.gd` y `tests/headless/table_rules.gd` cubren la mesa, y la mesa tiene sus
      tests de reglas y de reanudación (`<mesa>_rules`, `<mesa>_resume`, `art_<mesa>`), como Alicia
      ([mesas/ALICIA.md](mesas/ALICIA.md)).
- [ ] El bot azar hace menos que el novato, y el test chico `tests/headless/playtest_bot.gd` sigue pasando.

### Metas de F1c (bot medio salvo que diga otra cosa)

| Métrica | Meta | Dónde se lee en el informe |
|---|---|---|
| Duración media de una bola | 45–90 s | Resumen, "Segundos por bola" |
| Bolas perdidas por outlanes | 35–50 % (el centro no es la mayoría) | "Por dónde se pierde" |
| Diferencia outlane izq. – der. | < 10 puntos (medio **y experto**) | "Por dónde se pierde" |
| Partidas que llegan a la multibola | medio 30–50 %, novato 5–15 %, experto > 70 % | Avisos de inicio de multibola × bolas por partida (techo); ver abajo |
| Partidas con al menos un jackpot | 15–35 % | Avisos de jackpot × bolas por partida (techo) |
| Mayor fuente de puntos | < 35 % (experto y medio) | "Fuentes de puntos", primera fila |
| Bolas trabadas | 0 sin rescate | Línea de bolas salvadas/trabadas |
| Experto ÷ novato | 4×–10× en puntos por partida | Resumen, media por partida |

### Paridad con las otras mesas

- [ ] Segundos por bola del medio dentro de **±25 %** del promedio de las mesas existentes (propuesta; F1c pide
      "parejas" sin número).
- [ ] La mesa tiene una **jugada clara**: algún aviso de misión o jackpot que el experto saca al menos **3 veces más
      por bola** que el medio. Si no hay diferencia, la mesa es de suerte.

### Complejidad (que sea la siguiente del carrusel)

- [ ] Tiene **al menos un modo más** o **un eslabón más** en su cadena principal que la mesa anterior (§3).
- [ ] Usa **al menos una herramienta de §3 que la anterior no tenía**, y está escrita en su `docs/mesas/<MESA>.md`
      en la sección *Concepto*, como hace Alicia.
- [ ] Ese agregado **no** se logró achicando el hueco, los outlanes ni el salvabolas: la física y la geometría
      base son las de `table_base.tscn`.
- [ ] Todos los números de reglas viven en `resources/rules/<mesa>.tres`; nada cableado en el script de reglas.

### Mejoras del runner que harían falta para medir todo esto bien

Hoy dos metas se estiman con un techo. Para medirlas exactas, `session.gd` tendría que contar los avisos **por
partida** (en la línea `game` del `.jsonl`) y `report.gd` mostrar "% de partidas con multibola / jackpot". Además,
el bot no apunta a lo encendido: hasta que lo haga, las metas de llegada a la multibola se validan con el experto
como cota baja y con personas en F8.

### Antes de abrirla a personas

- [ ] Probada en el teléfono real (F7): que la jugada se entienda sin leer nada y que no haya rincones injustos.
- [ ] Capturas regeneradas con `tools/capture_screenshots.gd`.
- [ ] Pasa a la ronda de testers (F8) con su pregunta en el formulario: "¿se entiende qué hay que hacer?".
