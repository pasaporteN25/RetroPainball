# Backlog

Todo lo que falta, dividido en **7 categorías**. Cada tarea tiene un código (para referenciarla en
commits e issues) y la **fase** del roadmap en la que entra (ver README).

| Código | Categoría | Qué abarca |
|---|---|---|
| **G** | Gameplay | Física, piezas de la mesa y reglas genéricas que sirven para cualquier mesa |
| **S** | Mesas y skins | El sistema de temas y las 5 mesas como contenido (cruza arte, audio y gameplay) |
| **A** | Arte y efectos | Estilo visual, assets, luces, partículas, el "jugo" de los puntos y bonus |
| **M** | Audio y música | Efectos de sonido, OST abierta, créditos, música externa, plugin de música |
| **U** | Menú e interfaz | Carrusel, HUD, pausa, opciones, récords, primera partida |
| **P** | Plataforma Android | Teléfono real, rendimiento, plugin Kotlin base, firma, Play Store, Play Games |
| **Q** | Calidad y herramientas | Tests, CI, modo de pruebas, idiomas, licencias |

> **Mesas y skins** es la categoría que más pesa en este juego. Cada mesa es un *epic*: junta tareas de
> arte, audio y reglas, y se da por terminada cuando las tiene todas.

---

## G · Gameplay

| Código | Tarea | Fase |
|---|---|---|
| G-01 | Ajustar la sensación en un teléfono real (gravedad, fuerza y velocidad de los flippers, rebotes, tamaño de bola). Pasar esos números a un Resource `TablePhysics` para tunearlos sin tocar código | 2 |
| G-02 | Puerta de una vía a la salida del carril de lanzamiento (que la bola no vuelva al carril) | 2 |
| G-03 | Detectar bola trabada (quieta N segundos) y destrabarla | 2 |
| G-04 | Nudge/tilt: deslizar el pulgar hacia arriba o agitar el teléfono, con avisos y TILT | 3 |
| G-05 | Rollovers superiores (carriles que se encienden; los flippers rotan las luces) | 3 |
| G-06 | Blancos abatibles (drop targets) en banco y blancos fijos (standup) | 3 |
| G-07 | Multiplicador de bonus y conteo de bonus al perder la bola | 3 |
| G-08 | Multibola: bloquear 3 bolas, jackpot | 3 |
| G-09 | Skill shot según la potencia del lanzador | 3 |
| G-10 | Agujero que retiene y devuelve la bola (saucer/kicker) y spinner | 3 |
| G-11 | Rampas y órbitas con combos (en 2D: la bola cambia de capa de colisión al subir) | 3 |
| G-12 | Bola extra y kickback (salvador de outlane) | 3 |
| G-13 | Motor de reglas por datos: modos/misiones definidos en un Resource, no en código, para que cada mesa tenga las suyas (ver S-03) | 4 |

## S · Mesas y skins

| Código | Tarea | Fase |
|---|---|---|
| S-01 | Resource `TableTheme`: paleta, texturas, fuente, color del display, nombres de modos, música y créditos. Que las piezas existentes (flipper, bumper, pared, HUD) lo lean | 4 |
| S-02 | Escena base `table_base.tscn` heredable: cada mesa es una escena heredada + su tema + sus reglas | 4 |
| S-03 | Resource `TableRules`: modos, nombres, puntajes y objetivos por mesa (usa G-13) | 4 |
| S-04 | Revisión legal de cada tema: solo dominio público u originales; nada tomado de adaptaciones (ej. la Alicia de Disney); mascota de Linux propia o Tux con su atribución | 4 |
| S-05 | **Kernel Panic** (Linux/terminal): fósforo verde de CRT, pingüino propio, bumpers "daemons", multibola `fork()`, jackpot `sudo`, drenaje "segfault" | 4 |
| S-06 | **20.000 Leguas** (Verne): Nautilus steampunk, kraken que gira, la profundidad como progresión | 7 |
| S-07 | **Drácula** (Stoker): castillo, murciélagos, rampa Carfax, multibola a medianoche | 7 |
| S-08 | **Baker Street** (Holmes): niebla, lupa, pistas en los blancos que resuelven el caso | 7 |
| S-09 | **Alicia** (Carroll + ilustraciones de Tenniel): naipes como blancos, madriguera, gato que aparece y desaparece | 7 |

Cada mesa (S-05 a S-09) se cierra con: concepto, layout con su juguete propio, arte (A-08), reglas y
modos con nombres, playlist (M-03), entrada en el carrusel y su test (Q-04).

## A · Arte y efectos

| Código | Tarea | Fase |
|---|---|---|
| A-01 | Dirección de arte común: vectorial con brillo neón (escala bien, sirve para todos los temas y no depende de un ilustrador). Guía con grosores, paleta base y mockup de una mesa | 3 |
| A-02 | Brillo (glow) 2D y lamparitas de inserto en la mesa que se encienden (multiplicadores, objetivos) | 3 |
| A-03 | "Jugo": partículas en bumpers, flash y sacudida de pantalla, cámara lenta en el jackpot, estela de la bola | 3 |
| A-04 | Display: animaciones (parpadeo en el jackpot, cuenta de bonus, mensajes cortos) y color por skin | 3 |
| A-05 | Popups de puntaje con estilo por mesa (fuente, color, tamaño según los puntos) | 4 |
| A-06 | Fuente propia para la interfaz (licencia OFL) | 4 |
| A-07 | Pipeline de assets: SVG → importación, nombres, tamaño del APK | 4 |
| A-08 | Arte de cada mesa: fondo del playfield, piezas temáticas, mascota (una por S-05..S-09) | 4/7 |
| A-09 | Ícono de la app, splash y gráficos para Play Store (capturas, feature graphic) | 8 |

## M · Audio y música

| Código | Tarea | Fase |
|---|---|---|
| M-01 | Buses de audio (Música / Efectos / Voces) con volúmenes en opciones | 6 |
| M-02 | Efectos base: flipper, bumper, slingshot, lanzador, drenaje, bola salvada, jackpot (CC0 o generados con sfxr) | 3 |
| M-03 | Curar la OST abierta por mesa (CC0 / CC-BY, sin NC) con un registro de licencias `credits` que valida un test (Q-06) | 6 |
| M-04 | Reproductor de playlist por mesa: crossfade y orden aleatorio | 6 |
| M-05 | Créditos visibles: aviso "Sonando: tema — autor (licencia)" y pantalla de créditos | 6 |
| M-06 | Música dinámica: más intensidad o capas durante la multibola | 6 |
| M-07 | Modo "mi música": no pedir el foco de audio exclusivo, apagar la OST y dejar los efectos (investigar cómo maneja el foco Godot en Android) | 6 |
| M-08 | Plugin Kotlin: "Sonando ahora" y controles (pausa / siguiente) de cualquier app vía MediaSession (permiso opcional de notificaciones) | 6 |
| M-09 | Música local: elegir una carpeta (SAF) desde el plugin y reproducir MP3/OGG | 6 |
| M-10 | Spotify App Remote: investigar requisitos actuales y decidir (probablemente se descarta) | 6 |
| M-11 | Callouts / voces por mesa (opcional) | 7 |

## U · Menú e interfaz

| Código | Tarea | Fase |
|---|---|---|
| U-01 | Pasar el HUD de código a una escena editable que tome los colores del tema | 2 |
| U-02 | Menú de pausa completo: continuar, reiniciar, opciones, volver al carrusel | 2 |
| U-03 | Pantalla de título | 5 |
| U-04 | Carrusel de mesas estilo Guitar Hero 3: mesa inclinada en perspectiva que se balancea, deslizar para cambiar, preview de música y récord | 5 |
| U-05 | Récords: top 10 por mesa, más una pantalla de récords (las iniciales se quitaron: el puntaje se guarda solo, sin nombre) | 5 |
| U-06 | Fin de partida mejorado: bonus, posición en el top 10, "otra" (sin ingreso de iniciales) | 5 |
| U-07 | Opciones: volúmenes, vibración, altura de las zonas táctiles (o media pantalla completa), idioma | 5 |
| U-08 | Primera partida: indicación de cómo se juega con los dos pulgares | 5 |
| U-09 | Estadísticas por mesa (partidas, mejor bola, jackpots) | 8 |

## P · Plataforma Android

| Código | Tarea | Fase |
|---|---|---|
| P-01 | Probar en un teléfono real: sensación, latencia táctil, vibración | 2 |
| P-02 | Rendimiento y batería: pantallas de 60/120 Hz, costo de la física a 240 Hz | 2 |
| P-03 | Pantallas distintas: notch, bordes curvos, barra de gestos, tablets (hoy hay barras a los costados) | 2 |
| P-04 | Ciclo de vida: pausa en llamadas y notificaciones, botón atrás en cada pantalla | 2 |
| P-05 | Base del plugin Android en Kotlin (módulo en Android Studio, plugin v2 de Godot, build) | 6 |
| P-06 | Google Play Games: rankings online y logros (sobre P-05) | 8 |
| P-07 | Release: firma, AAB, cuenta de Play Console, ficha, clasificación de contenido, política de privacidad | 8 |
| P-08 | Tamaño del APK: excluir lo que no se usa | 8 |
| P-09 | Decidir el modelo: gratis / pago / mesas extra (decisión pendiente, afecta P-07) | 8 |

## Q · Calidad y herramientas

| Código | Tarea | Fase |
|---|---|---|
| Q-01 | CI en GitHub Actions con la suite headless (el repo es público: los minutos son gratis) | 2 |
| Q-02 | Modo de pruebas: saltar a la multibola, bola infinita, ver las colisiones, velocidad del juego (skill `godot-test-mode`) | 3 |
| Q-03 | Tests por pieza nueva (cada pieza de G y cada regla) | 3+ |
| Q-04 | Test por mesa: carga, y simulación con disparos al azar durante N segundos sin que la bola se escape ni se trabe | 4+ |
| Q-05 | Idiomas: español → inglés (skill `godot-localization`) | 8 |
| Q-06 | Registro de licencias (música, fuentes, arte) validado por un test: nada sin autor y licencia compatible | 6 |
