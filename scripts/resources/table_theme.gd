class_name TableTheme
extends Resource
## Aspecto y textos de una mesa (S-01): paleta, color del display, fuente y nombres.
## Hay un `.tres` por mesa en `res://resources/themes/<table_id>.tres`; HUD, pausa, opciones,
## fin de partida, récords, selector y popups lo leen con `GameState.active_theme()`.
## Los valores por defecto son los de Kernel Panic: una mesa nueva solo pisa lo que cambia.

const DIR := "res://resources/themes/"

@export var table_id := "kernel_panic"
@export_group("Nombres y textos")
@export var display_name := "Kernel Panic"
## Línea bajo el título en la tarjeta del selector, y resumen y frase extra (puede ir vacía).
@export var subtitle := "Pinball clásico"
@export var summary := "Carriles y blancos en un circuito retro"
@export var tagline := ""
@export var pause_title := "PAUSA"
@export var game_over_title := "FIN DEL JUEGO"
@export var records_title := "RÉCORDS"
@export var new_record_text := "¡NUEVO RÉCORD!  PUESTO 1"
@export var no_bonus_text := "SIN BONUS"
## Nombres de modos que cada mesa muestra al jugador (clave lógica -> texto). Reservado para
## cuando las reglas de cada mesa dejen de tener los textos cableados.
@export var mode_names: Dictionary = {}
@export_group("Paleta de acento")
## Acento de la tarjeta del selector.
@export var select_accent := Color("#8cead2")
## Acento de la pestaña y del primer puesto en récords.
@export var records_accent := Color("#75e6c6")
## Acento de los menús de pausa y opciones.
@export var menu_accent := Color("#75e6c6")
@export_group("HUD y menús")
@export var text_color := Color("#f3ead8")
@export var muted_color := Color("#a7b5b9")
@export var score_label_color := Color("#ffbc6b")
@export var record_label_color := Color("#a7b5b9")
@export var balls_label_color := Color("#75e6c6")
@export var toast_accent := Color("#75e6c6")
@export var game_over_accent := Color("#ff786b")
@export var game_over_bonus_color := Color("#ffbc6b")
@export var game_over_record_color := Color("#75e6c6")
@export var panel_ink_color := Color("#101619")
@export var panel_frame_color := Color("#435052")
@export var backdrop_color := Color(0.015, 0.024, 0.032, 0.86)
@export_group("Display")
## Color de los segmentos encendidos del marcador de 7 segmentos.
@export var display_color := Color("#ffb465")
@export_group("Fuente")
## null = la fuente por defecto del proyecto.
@export var font: Font
@export_group("Popups de puntaje")
@export var popup_font_names := PackedStringArray(["monospace"])
@export var popup_color := Color("#83ff91")
@export var popup_plate_color := Color("#071b0d")
@export var popup_border_color := Color("#83ff91")
@export_group("Mesa")
## Color de las lamparitas del multiplicador de bonus.
@export var lamp_tint := Color("#83ff91")


## Tema de la mesa `id`. Si no existe devuelve el de Kernel Panic, y si tampoco, uno por defecto.
static func for_table(id: String) -> TableTheme:
	for candidate in [id, "kernel_panic"]:
		var path := DIR + str(candidate) + ".tres"
		if ResourceLoader.exists(path):
			var theme := load(path) as TableTheme
			if theme:
				return theme
	return TableTheme.new()
