extends RefCounted
## Navegación "atrás" compartida (botón/gesto atrás de Android, Esc y B del mando).
##
## En Android el atrás llega como NOTIFICATION_WM_GO_BACK_REQUEST y en PC como la acción ui_cancel (o pause).
## Cada pantalla maneja los dos caminos y los manda a un único método; `claim()` evita que un mismo atrás
## se atienda dos veces en el mismo frame (por ejemplo, cuando el padre y el hijo reciben la notificación).

const TITLE_SCENE := "res://scenes/title.tscn"
const SELECT_SCENE := "res://scenes/table_select.tscn"

## Pantalla a la que vuelve Récords (la configura quien la abre; por defecto, el selector).
static var records_return := ""

## Pantalla a la que vuelve Acerca de cuando se abre como escena (la configura quien la abre; por defecto, el título).
static var about_return := ""

static var _last_frame := -1


## True si el evento es un atrás de teclado/mando (Esc, B, P o Start).
static func is_back_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")


## Reclama el atrás de este frame: devuelve true solo la primera vez.
static func claim() -> bool:
	var frame := Engine.get_process_frames()
	if frame == _last_frame:
		return false
	_last_frame = frame
	return true


## Olvida el frame reclamado (los tests simulan varios atrás en un mismo frame).
static func reset() -> void:
	_last_frame = -1


## Destino de Récords: se consume al usarlo.
static func take_records_return() -> String:
	var path := records_return if not records_return.is_empty() else SELECT_SCENE
	records_return = ""
	return path


## Destino de Acerca de: se consume al usarlo.
static func take_about_return() -> String:
	var path := about_return if not about_return.is_empty() else TITLE_SCENE
	about_return = ""
	return path
