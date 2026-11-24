# Plan: pulir la beta de Retro Pinball

*Escrito el 24 de noviembre de 2026, después de subir la versión 0.9.0 (PR #67).*

El objetivo es **perfeccionar la beta con las cuatro mesas que ya existen** antes de seguir con
mesas o funciones nuevas: que se sientan bien en un teléfono real, que sean justas pero desafiantes,
que tengan música y que la app diga quién la hizo. Este documento es el plan; no hay nada
implementado todavía.

## Cómo usar este documento (para el agente que lo recibe)

1. Leé este archivo completo, después `README.md` y `docs/BACKLOG.md` (los códigos `G-01`, `S-05`,
   `M-03`… son tareas del backlog; cada una tiene un issue en GitHub con el código al principio del
   título).
2. Cada **frente** (F0…F8) es un bloque de trabajo con su objetivo, sus archivos, su criterio de
   terminado y el agente sugerido. Trabajá un frente por rama y un PR por frente.
3. Respetá la tabla de **archivos por frente**: dos frentes en paralelo no tocan los mismos archivos.
4. Lo marcado como **Decisión de Lucas** no se resuelve solo: se pregunta antes de implementar.
5. Nada de esto se da por terminado sin `.\tools\test.ps1` en verde y sin probarlo en la app.

## ¿Y Kotlin?

**Hoy no hay nada de Kotlin en el repo y el juego no lo necesita para andar bien.**

- Todo el juego (física, mesas, reglas, menús) está en **GDScript** sobre **Godot**. El motor en sí
  está escrito en C++: la física, el dibujo y el audio corren en código nativo, y GDScript solo
  maneja la lógica del juego.
- En el APK/AAB, Godot ya trae su propia capa de Android en Java/Kotlin, que arranca el motor,
  maneja la pantalla, el toque y la vibración. No escribimos nada ahí: viene en la plantilla.
- Lo que se decidió el 20 de noviembre fue sumar **más adelante un plugin de Android en Kotlin**
  (P-05) para cosas que Godot no hace solo: mostrar y controlar la música de otras apps con
  MediaSession (M-08), elegir una carpeta de música propia (M-09) y Google Play Games (P-06).
  Es para **integrarse con Android**, no para que el juego corra más rápido.
- Si en un teléfono real el juego anda lento, la solución no es Kotlin sino medir con el profiler
  de Godot y optimizar el GDScript caliente o, en el peor caso, pasar una pieza a C++ con
  GDExtension. Con 240 ticks de física por segundo conviene medirlo en P-02 antes de suponer nada.

**Recomendación:** dejar el plugin de Kotlin para después de la beta. Ninguna de las mejoras de
este plan lo necesita.

## Quién hace qué

| Agente | Fuerte en | Lo uso para |
|---|---|---|
| **Claude Opus 5.5** | Diseño, arquitectura, analizar resultados y criticar decisiones | Diseñar el sistema de playtesting (F1), analizar los informes y proponer el ajuste de cada mesa, revisar los PRs de los demás |
| **Claude Sonnet 5.5** | Implementación rápida y prolija de tareas bien definidas, con tests | Implementar el bot y el runner (F1), la multibola de Kernel Panic (F2), la pantalla Acerca de (F6), integrar la música (F5b) |
| **Codex · GPT 6.2 Sol** | Segundo implementador | Retoques visuales (F3), AGENTS.md (F0) y **revisión cruzada** de los PRs que hace Claude |
| **Codex · GPT 6.1 Terra** | Tareas de investigación y volumen | Investigar música libre (F5a), correr las tandas de simulación y armar las tablas comparativas (F1c) |

No conozco las capacidades exactas de los modelos Sol y Terra; esta asignación es una sugerencia.
La única regla firme: **el que implementa no es el que revisa**. Un PR de Claude lo revisa Codex
y viceversa.

### Reglas para que no se pisen

- Una rama por frente: `beta/f2-kernel-multiball`, `beta/f6-about`, etc. Un PR por frente contra
  `master`, con `Closes #N` del issue del backlog para que se cierre solo al mergear.
- Antes de abrir el PR: `.\tools\test.ps1` en verde (hoy 54 tests) y, si cambia algo visible,
  capturas nuevas con `tools/capture_screenshots.gd`.
- Godot está en `C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe`. Push por HTTPS desde Git
  Bash: `git -c http.sslBackend=schannel push`.
- Textos del juego, commits y docs en **español rioplatense** (voseo), como el resto del repo.
- Lo que va en la tabla de archivos de un frente lo toca solo ese frente mientras esté abierto.

## Orden de trabajo

```
Ola 1 (en paralelo)      F0 → (F1a · F2 · F3 · F5a · F6) · F7 (Lucas)
Ola 2                    F1b informe base → F1c ajuste de mesas · F5b integrar música
Ola 3                    F8 versión 0.9.x → prueba cerrada con testers → F1d guía para mesas nuevas
```

F0 va primero porque son las reglas que leen todos los agentes. F1c espera a F2, porque la
multibola cambia las reglas de Kernel Panic y el informe tiene que medir la versión nueva.

| Frente | Tema | Agente | Estimación | Depende de |
|---|---|---|---|---|
| F0 | Reglas para agentes (`AGENTS.md`) | Sol | 1 h | — |
| F1 | Playtesting masivo con bots | Opus + Sonnet + Terra | 3–4 días | F0; F1c además F2 |
| F2 | Multibola `fork()` y jackpot `sudo` en Kernel Panic | Sonnet | ½–1 día | F0 |
| F3 | Retoques visuales | Sol | 2–3 h | F0 |
| F4 | Fondo de 20.000 Leguas | Lucas, y quizás Sonnet | 0 h o 1 día | Decisión de Lucas |
| F5 | Música libre: investigación e integración | Terra (a) + Sonnet (b) | 1 día + ½ día | F5b espera la elección de Lucas |
| F6 | Pantalla "Acerca de" y créditos | Sonnet | ½ día | Decisión de Lucas (nombre y licencia) |
| F7 | Prueba en teléfono real | Lucas | 1–2 h por tanda | Beta en Prueba interna |
| F8 | Versión 0.9.x y ronda con testers | Lucas + Opus | continuo | Olas 1 y 2 |

---

## F0 · Reglas para agentes

Codex lee `AGENTS.md` y Claude lee `CLAUDE.md`; hoy el repo no tiene ninguno.

- Crear `AGENTS.md` en la raíz con lo de "Reglas para que no se pisen", cómo correr los tests,
  dónde están las cosas (`scripts/table`, `resources/rules`, `resources/themes`, `tests/headless`)
  y el estilo (GDScript tipado, comentarios `##` en español, tests en `tests/headless/<tema>.gd`).
- Crear `CLAUDE.md` con una sola línea que apunte a `AGENTS.md`, así hay una única fuente.

**Terminado cuando:** los dos archivos están en master.

## F1 · Playtesting masivo con bots

La idea es jugar **miles de partidas por mesa** sin pantalla, medir todo y usar esos números para
mejorar las mesas actuales y para saber cómo diseñar mesas mejores y más difíciles.

Ya existe una base: `tests/headless/table_random.gd` (Q-04) juega 60 segundos al azar en cada mesa
y verifica que la bola no se escape ni se trabe. F1 lo lleva de "no se rompe" a "¿es divertido y
justo?".

### F1a · El bot y el runner (Opus diseña, Sonnet implementa)

- **Bot jugador** (`tools/playtest/bot.gd`): mira la posición y velocidad de cada bola y aprieta
  los flippers con las mismas acciones de input que el jugador (`flipper_left`, `flipper_right`,
  `launch`). Tiene **niveles de habilidad** parametrizados:
  - *Novato*: reacción lenta (~180 ms), error grande en el momento del golpe, nunca retiene la bola.
  - *Medio*: reacción ~110 ms, a veces atrapa la bola (flipper apretado) y apunta a lo que esté
    encendido.
  - *Experto*: reacción ~70 ms, atrapa y apunta a los objetivos activos de las reglas, usa el nudge
    con moderación.
  - *Azar*: lo de `table_random.gd`, como control.
- **Runner** (`tools/playtest/run.gd` + `tools/playtest.ps1`): recibe mesa, bot, cantidad de bolas
  y semilla; corre headless con `Engine.time_scale` alto y varios procesos en paralelo (uno por
  núcleo). Primero hay que verificar que acelerar el tiempo no cambia la física: misma semilla a
  1x y a 4x debería dar resultados parecidos. Si no, usar `--fixed-fps` y medir.
- **Métricas por bola y por partida**, guardadas en `build/playtest/<fecha>/<mesa>_<bot>.jsonl`:
  - puntaje por bola y por partida, duración de cada bola;
  - **por dónde se perdió** (outlane izquierdo, outlane derecho, centro, entre flippers) y si
    había salvabolas o kickback;
  - golpes por pieza (bumpers, blancos, rampas, spinner…) y **mapa de calor** de por dónde anda
    la bola;
  - cuántas partidas llegan a cada modo, misión, multibola y jackpot, y en cuánto tiempo;
  - bolas trabadas, rescates del detector de trabas, TILT;
  - aporte de cada fuente de puntos al total, para ver qué pieza paga de más o de menos.
- **Informe** (`tools/playtest/report.gd`): un Markdown en `docs/playtest/<fecha>.md` con tablas
  por mesa y bot, más un PNG con el mapa de calor sobre la mesa. Comparar dos corridas (antes y
  después de un cambio) en la misma tabla.

No es un test de la suite: tarda mucho. Lo que sí entra en la suite es un **test chico del bot**
(50 bolas, debe superar al bot al azar) para que no se rompa sin que nadie lo note.

**Terminado cuando:** `.\tools\playtest.ps1 -Table kernel_panic -Bot medio -Balls 2000` genera el
informe y el test chico corre en `test.ps1`.

### F1b · Informe base (Terra corre, Opus analiza)

Correr **las 4 mesas × los 4 bots × 2.000 bolas** con la versión actual (con F2 ya mergeado) y
dejar el informe en `docs/playtest/`. Esta es la línea de base contra la que se compara todo.

### F1c · Ajustar las mesas existentes (Opus propone, Sonnet aplica, Terra mide)

Opus lee el informe y propone cambios **en los datos, no en el código** (`resources/rules/*.tres`,
`resources/table_physics.tres`, posiciones en las escenas), cada uno con su hipótesis: "el outlane
derecho se lleva el 45 % de las bolas → acercar el poste 6 px". Se aplica, se vuelve a medir y
queda si mejora.

Objetivos de partida para el **bot medio** (para afinar con lo que digan los testers en F8):

| Métrica | Objetivo |
|---|---|
| Duración media de una bola | 45–90 s |
| Bolas perdidas por outlanes | 35–50 % (por el centro no debería ser la mayoría) |
| Diferencia entre outlane izquierdo y derecho | menos de 10 puntos |
| Partidas que llegan a la multibola | 30–50 % (novato 5–15 %, experto más de 70 %) |
| Partidas con al menos un jackpot | 15–35 % |
| Ninguna pieza paga más del | 35 % del puntaje total |
| Bolas trabadas | 0 sin rescate |
| Puntaje del experto sobre el del novato | 4× a 10× (si es menos, la habilidad no importa) |

Además, que las 4 mesas queden **parejas entre sí** en duración por bola, y que cada una tenga una
"jugada" clara que el experto aprende y el novato no.

### F1d · Guía para mesas mejores y más difíciles (Opus)

Con lo aprendido, escribir `docs/DISENO_MESAS.md`:

- **Palancas de dificultad**, cuánto mueve cada una y en qué sentido: ancho de outlanes y postes,
  tiempo de salvabolas, cargas del kickback, fuerza y largo de los flippers, gravedad, rebote de
  los slingshots, largo de las misiones, tiempo de los modos, cuántos blancos hacen falta para la
  multibola.
- **Curva de progresión**: qué tiene que pasar en el primer minuto, a los cinco y a los veinte.
- **Checklist de mesa nueva**: métricas que tiene que pasar en el runner antes de ser jugable.
- **Propuesta de dificultad** para el jugador. *Decisión de Lucas:* una dificultad por mesa
  (mesas más difíciles en el carrusel), un selector Normal/Experto, o un modo "Torneo" con
  salvabolas corto y sin bola extra.

### Playtesting con personas

Los bots dicen si una mesa es justa; si es divertida lo dicen las personas. Eso va en F8. La beta
**no manda datos** (lo dice la política de privacidad), así que la opinión de los testers se junta a
mano con un formulario, no con telemetría.

## F2 · Multibola `fork()` y jackpot `sudo` en Kernel Panic (S-05)

Es la única mesa sin multibola propia. Lo que promete el diseño de S-05:

- **`fork()`**: completar el banco de blancos y los rollovers "carga" procesos; con N procesos se
  habilita la multibola y la bola que entra al saucer se "bifurca" en 2 o 3 bolas.
- **`sudo`**: durante la multibola, una jugada difícil (por ejemplo, el spinner o la órbita
  encendida) prende el jackpot `sudo`; pegarle paga el jackpot y lo cuenta en las estadísticas.
- **Segfault**: el drenaje ya tiene su efecto (`scripts/fx/kernel_segfault.gd`); que la multibola
  se termine al quedar una sola bola, con un mensaje propio.

Archivos: un `scripts/table/kernel_rules.gd` nuevo (como `dracula_rules.gd`), su grupo de exports en
`scripts/resources/table_rules.gd` y `resources/rules/kernel_panic.tres` (hoy usa un `kraken_jackpot`
heredado con un mensaje en metros que no corresponde a Kernel Panic), `scenes/main.tscn` /
`scenes/kernel_layout.tscn` si hacen falta lamparitas, y HUD/mensajes. El mecanismo de multibola ya
existe (lo usan Drácula y el modo de pruebas con F1).

**Terminado cuando:** hay test en `tests/headless/kernel_multiball.gd` (bloqueo, bifurcación,
jackpot, fin de la multibola, guardado y continuación en medio de la multibola) y se jugó en la app.

## F3 · Retoques visuales

- El arco superior tapa el título "20.000 LEGUAS" (`scripts/table/nautilus_art.gd`) y el cartel
  y subtítulo de Alicia (`scripts/table/alice_art.gd`): bajar o achicar los títulos.
- El selector de mesas (`scripts/ui/table_select.gd`) deja mucho espacio vacío: usar ese lugar
  para el récord y las estadísticas de la mesa, o agrandar la mesa en perspectiva (U-04).
- Regenerar las capturas de Play (`tools/capture_screenshots.gd`).

**Terminado cuando:** las capturas nuevas no tienen superposiciones y los tests de arte pasan.

## F4 · Fondo de 20.000 Leguas

`assets/nautilus_playfield.webp` es una imagen pintada, en otro estilo que el resto, y figura con
autor "Newman" en el commit 2287def sin fuente registrada.

- **Decisión de Lucas:** si sabés de dónde salió y que se puede usar, se anota la fuente y la
  licencia en `resources/credits.json` y listo.
- Si no se sabe, reemplazarla por arte vectorial con brillo neón como el resto de las mesas (A-01),
  dibujado en código como `dracula_art.gd`. Es ~1 día de Sonnet.

Conviene resolverlo **antes de abrir la prueba cerrada**, porque la van a ver personas de afuera.

## F5 · Música libre

Hoy solo hay efectos: las listas de música de las cuatro mesas están vacías. El reproductor (M-04)
y el registro de licencias (`resources/credits.json`, validado por un test) ya existen.

### F5a · Investigación y opciones (Terra)

Entregar `docs/MUSICA.md` con **al menos 3 opciones por mesa y 3 para los menús**. Cada opción es
una propuesta de estilo con 2 o 3 temas concretos:

| Para cada tema | Detalle |
|---|---|
| Título, autor y link a la página original | De donde se baja, no de un espejo |
| Licencia exacta | **CC0 o CC-BY** (3.0 o 4.0). **Nada con NC** (no comercial), porque cierra la puerta a cobrar más adelante (P-09). Evitar ND si hay que cortarlo o hacerle un loop |
| Duración y si hace loop | Que no se note el corte |
| Peso en OGG a ~96 kbps | Presupuesto total: **15 MB** (el AAB ya pesa 52 MB) |
| Por qué va con la mesa | Una línea |

Direcciones para buscar (Terra puede proponer otras):

- **Menús / título**: synthwave o chiptune arcade, con energía pero sin cansar.
- **Kernel Panic**: chiptune, 8-bit o electrónica de terminal; algo "hacker" con pulso.
- **20.000 Leguas**: ambiente submarino, orquestal de aventura o steampunk; más lento.
- **Drácula**: órgano gótico, darkwave o tensión de cine de terror clásico (sin sustos).
- **Alicia**: caprichoso, caja de música, vals o folk juguetón.
- **Multibola** (opcional, M-06): una versión más intensa o un tema más rápido por mesa.

Fuentes para revisar, verificando **la licencia de cada tema por separado** (en estos sitios cada
autor elige la suya): OpenGameArt.org, Free Music Archive, ccMixter, incompetech (Kevin MacLeod,
CC-BY), Bandcamp de autores con temas CC, y Pixabay Music o la biblioteca de YouTube Studio solo si
su licencia permite incluirlos en un juego distribuido (leerla; no son Creative Commons).

**Terminado cuando:** `docs/MUSICA.md` está en un PR y Lucas eligió una opción por mesa.

### F5b · Integrar la música elegida (Sonnet)

- Bajar los temas, convertirlos a OGG y ponerlos en `assets/music/<mesa>/`.
- Cargar las listas en `resources/themes/*.tres` y una lista para los menús.
- Una entrada por tema en `resources/credits.json` (kind `music`, autor, licencia, link).
- **M-05**: aviso "Sonando: tema — autor (licencia)" al empezar cada tema, y que los créditos de
  música se vean en la pantalla de F6.
- Medir el peso del AAB antes y después.

**Terminado cuando:** cada mesa tiene música, el test de créditos pasa y el aviso se ve en la app.

## F6 · Pantalla "Acerca de" y créditos

Una pantalla nueva, a la que se entra desde **Opciones** y desde el título, con:

- **Retro Pinball** y la versión (`0.9.x (code N)`). Hoy la versión vive solo en
  `export_presets.cfg`: sumar `application/config/version` en `project.godot` y que
  `tools/release.ps1` la actualice al mismo tiempo, así el juego la puede mostrar.
- **Hecho por** y el nombre como quieras que aparezca. *Decisión de Lucas:* nombre completo,
  apodo o usuario de GitHub, y si querés un link de contacto. **No poner el mail** salvo que lo
  pidas.
- **Código fuente**: botón a `https://github.com/pasaporteN25/RetroPainball` (con `OS.shell_open`)
  y botón para reportar un problema (`/issues`).
- **Política de privacidad**: botón al link de `docs/PRIVACY.md`.
- **Créditos**: arte, efectos y música leídos de `resources/credits.json` (la misma lista que
  valida el test), así nunca se desactualiza.
- **Hecho con Godot Engine**: la licencia MIT de Godot **exige** incluir su aviso de copyright en el
  juego, junto con los de las bibliotecas que trae (FreeType, etc.). Mostrarlos con
  `Engine.get_license_text()` y `Engine.get_copyright_info()`. Hoy falta, y es un requisito real
  de la licencia.
- **Licencia del juego**: el repo es público pero **no tiene archivo `LICENSE`**, así que hoy nadie
  tiene permiso legal de reusar el código. *Decisión de Lucas:* MIT (cualquiera puede reusar),
  GPL-3.0 (pueden reusar si publican sus cambios) o "todos los derechos reservados" (se ve pero no
  se reusa). El arte y la música pueden tener otra licencia que el código.

Archivos: `scenes/about.tscn` y `scripts/ui/about_screen.gd` nuevos, un botón en
`scripts/ui/options_menu.gd` y en `scripts/ui/title_screen.gd`, botón atrás de Android como el resto
de las pantallas, y un test `tests/headless/about_screen.gd`.

**Terminado cuando:** la pantalla se ve, el botón atrás vuelve, los links abren y el test pasa.

## F7 · Prueba en teléfono real (Lucas)

Con la beta en Prueba interna, instalala desde Play y anotá:

- **Sensación** (G-01): ¿los flippers responden ya? ¿la bola es muy rápida o muy lenta? ¿pesa?
- **Toque**: ¿las zonas de los pulgares están cómodas? ¿algún toque no se registró?
- **Vibración**: ¿se siente bien, es mucha, es poca?
- **Pantalla** (P-03): notch, bordes curvos, barra de gestos; ¿algo tapado?
- **Rendimiento** (P-02): ¿se traba en algún momento? ¿calienta o gasta mucha batería en 15 minutos?
- **Ciclo de vida** (P-04): entra una llamada o una notificación, salís y volvés; ¿pausa y sigue?

Pasá las notas a un issue por tema. Los números de sensación se ajustan en
`resources/table_physics.tres` sin tocar código.

## F8 · Versión 0.9.x y ronda con testers

1. Juntar lo de las olas 1 y 2, `.\tools\release.ps1 -VersionName 0.9.1`, subir a Prueba interna,
   probarlo vos (F7) y promoverlo a Prueba cerrada.
2. **Formulario para testers** (Google Forms, lo arma Lucas): mesa favorita y por qué, la más
   difícil y la más fácil, ¿la bola se pierde injustamente?, ¿se entiende qué hay que hacer en cada
   mesa?, ¿la música va con la mesa?, teléfono y modelo, algo que te frustró, algo que te encantó.
3. Opus triagea las respuestas: cada problema repetido es un issue, y las opiniones de dificultad
   ajustan los objetivos de F1c.
4. Repetir cada 1 o 2 semanas mientras corre la prueba cerrada de 14 días con 12 testers.

## Fuera de este plan (después de la beta)

Inglés (Q-05), plugin de Android en Kotlin (P-05, M-07…M-10), Google Play Games (P-06), la mesa de
Baker Street (S-08), callouts y voces (M-11) y el modelo de negocio (P-09).

## Decisiones de Lucas pendientes

| # | Decisión | Afecta |
|---|---|---|
| 1 | Procedencia del fondo de 20.000 Leguas, o reemplazarlo | F4 |
| 2 | Cómo aparece tu nombre en "Acerca de" y si va un contacto | F6 |
| 3 | Licencia del código (MIT, GPL-3.0 o reservada) | F6 |
| 4 | Música: una opción por mesa de `docs/MUSICA.md` | F5b |
| 5 | Dificultad: por mesa, selector Normal/Experto o modo Torneo | F1d |
| 6 | Si la asignación de agentes de arriba te sirve o la cambiás | todo |

## En espera (actualizado el 24 de noviembre de 2026)

- **Música (F5): en espera.** Lucas la ve más tarde. **Antes de subir una versión a Play hay que elegir
  algunos temas libres (CC0 o CC-BY, sin NC)**: hoy las listas de música de las cuatro mesas están vacías.
  Hasta entonces no se publica una beta que prometa música. Lo que sigue pendiente es F5a (`docs/MUSICA.md`)
  y F5b.
- **Fondo de 20.000 Leguas (F4): en espera.** `assets/nautilus_playfield.webp` no tiene procedencia
  registrada (ver `resources/credits.json`). Hay que saber de dónde salió o reemplazarlo antes de abrir
  la prueba cerrada.
- **Resueltas:** nombre en "Acerca de" (Lucas Felici, pasaporteN25) y licencia del código (GPL-3.0).
- **Descartado:** F1d no incluye selector de dificultad; el juego no tiene niveles y la complejidad crece
  de mesa en mesa.
