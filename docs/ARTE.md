# Dirección de arte

Arte vectorial original, impreso sobre un tablero oscuro; las piezas y la bola deben conservar una silueta clara. Las coordenadas son de Table (720 px de ancho).

- **Kernel Panic:** fondo tinta `#070c14` / `#0e2029`, pistas `#2a6c68`, fósforo `#69e4bc`, acero `#637984`, acentos ámbar `#f6ad5d` y óxido `#954637`.
- **20.000 Leguas:** agua oscura y herrajes de bronce; turquesas `#69f5d5` y `#8bffe5`, bronce `#c59453` / `#c39257`, luces cálidas `#ffe1a3` y sombras `#362c24`.

Usar líneas de 1–2 px para pistas y detalles, 2–3 px para contornos y acentos; reservar trazos más gruesos para halos tenues. El brillo acompaña la forma, con transparencia baja y sin borrar contraste ni tapar piezas. El CRT respira lentamente y sus líneas son discretas; evitar destellos rápidos o de alto contraste.

En móvil preferir primitivas y geometría reutilizada, pocas capas y animaciones cortas; apagar el procesamiento de efectos cuando terminan. No generar recursos ni arreglos por cuadro. Comprobar rendimiento real en teléfono antes de sumar partículas o capas.

S-04: personajes, dibujos y marcas deben ser originales o de dominio público comprobado; registrar autoría y licencias cuando corresponda. No copiar mascotas existentes ni diseños de adaptaciones protegidas. El pingüino y los daemons de Kernel Panic son diseños propios.

## Drácula

Noche `#0b0a14`, azul `#1b2140`, carmesí `#9e1b32`, hueso `#e9e1cf`, plata lunar `#c9d3e6`, oro viejo `#c9a35a` y niebla `#3a4468`. Castillo y murciélagos son dibujos vectoriales originales inspirados en la novela de dominio público, sin elementos de adaptaciones cinematográficas. Dejar tenues las zonas bajo las piezas y libre la franja del multiplicador. Medianoche tiñe lentamente el cielo y el relámpago es infrecuente, suave y sin parpadeos rápidos. En móvil se reutiliza la geometría de ocho murciélagos, con pocas bandas de niebla y redibujado limitado a 20 Hz; comprobar rendimiento en dispositivo.

## Agregar una mesa con su `TableTheme` (S-01)

Los colores y textos de interfaz de cada mesa viven en un Resource `TableTheme` (`scripts/resources/table_theme.gd`), uno por mesa en `resources/themes/<table_id>.tres`. Pasos:

1. Elegir el `table_id` (el mismo del `@export var table_id` de la escena y de `GameState`) y duplicar `resources/themes/kernel_panic.tres` como `resources/themes/<table_id>.tres` (o crear un `TableTheme` nuevo en el inspector). Los campos que no se tocan toman los valores por defecto del script, que son los de Kernel Panic.
2. Completar: `display_name`, `subtitle`, `summary`, `tagline` (selector), `select_accent` / `records_accent` / `menu_accent`, `popup_*` (fuente y colores de los popups de puntaje), `lamp_tint`, `display_color` (7 segmentos) y, si hace falta, `font` y la paleta del HUD (`text_color`, `score_label_color`, `game_over_accent`, etc.).
3. Sumar el id a `TABLE_IDS` de `scripts/ui/records_screen.gd` y la tarjeta en `scripts/ui/table_select.gd` (la ilustración sigue dibujándose ahí).
4. Leer siempre el tema con `GameState.active_theme()` (mesa activa) o `GameState.active_theme("<id>")`; no escribir colores por mesa con `if table_id == ...`. Si el id no tiene `.tres`, se usa el de Kernel Panic.
5. Agregar la mesa a `tests/headless/table_theme.gd`.
