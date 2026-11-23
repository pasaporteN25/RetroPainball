extends RefCounted
## Lee y escribe una partida por mesa en el directorio de datos del juego.

const VERSION := 1
const MAX_FILE_BYTES := 4096
const MAX_BALLS := 3
const STATE_KEYS := [
	"table_id", "score", "balls_left", "balls", "serve_remaining",
	"save_remaining", "save_armed", "sonar_mask", "depth",
]
## Claves opcionales: las partidas guardadas antes del bonus siguen siendo válidas.
const BONUS_KEYS := ["bonus", "bonus_multiplier"]
## G-12: bolas extra y kickback. Solo aparecen junto con las claves del bonus.
const EXTRA_KEYS := ["extra_balls", "extra_awarded", "kickback_ready"]
const MAX_BONUS := 10000000
const BALL_KEYS := ["position", "velocity", "spin", "rotation"]


static func load_run(table_id: String, directory: String) -> Dictionary:
	if not _valid_table(table_id):
		return {}
	var file := FileAccess.open(_run_path(table_id, directory), FileAccess.READ)
	if file == null:
		return {}
	var size := file.get_length()
	# Prefijo de longitud de store_var(), datos y suma de control de cuatro bytes.
	if size < 16 or size > MAX_FILE_BYTES or file.get_32() != size - 8:
		return {}
	var payload := file.get_buffer(size - 8)
	if (hash(payload) & 0xffffffff) != file.get_32():
		return {}
	file.seek(0)
	var saved: Variant = file.get_var(false)
	if not saved is Dictionary or saved.size() != 2:
		return {}
	var version: Variant = saved.get("version")
	if not version is int or version != VERSION:
		return {}
	var state: Variant = saved.get("state")
	if not state is Dictionary or not _valid_state(state, table_id):
		return {}
	return state


static func save_run(state: Dictionary, directory: String) -> Error:
	var table_id: Variant = state.get("table_id")
	if not table_id is String or not _valid_table(table_id) or not _valid_state(state, table_id):
		return ERR_INVALID_DATA
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if error != OK:
		return error
	var path := _run_path(table_id, directory)
	var pending := "%s.%d.tmp" % [path, OS.get_process_id()]
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var saved := {"version": VERSION, "state": state}
	if file.store_var(saved, false) and file.store_32(hash(var_to_bytes(saved)) & 0xffffffff):
		file.flush()
		error = file.get_error()
	else:
		error = ERR_FILE_CANT_WRITE
	file.close()
	if error == OK:
		# El temporal vive al lado del archivo final para reemplazarlo con un solo rename.
		error = DirAccess.rename_absolute(pending, path)
	if error != OK:
		DirAccess.remove_absolute(pending)
	return error


static func clear_run(table_id: String, directory: String) -> Error:
	if not _valid_table(table_id):
		return ERR_INVALID_PARAMETER
	var path := _run_path(table_id, directory)
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(path)


static func _run_path(table_id: String, directory: String) -> String:
	return ProjectSettings.globalize_path(directory.path_join(table_id + ".save"))


static func _valid_table(table_id: String) -> bool:
	return table_id == "kernel_panic" or table_id == "nautilus" or table_id == "dracula" or table_id == "alicia"


static func _valid_state(state: Dictionary, table_id: String) -> bool:
	if not state.has_all(STATE_KEYS):
		return false
	var base_size := STATE_KEYS.size() + BONUS_KEYS.size()
	var has_bonus: bool = state.size() >= base_size and state.has_all(BONUS_KEYS)
	var has_extra: bool = has_bonus and state.size() == base_size + EXTRA_KEYS.size() and state.has_all(EXTRA_KEYS)
	if state.size() != STATE_KEYS.size() and not (has_bonus and (state.size() == base_size or has_extra)):
		return false
	if has_extra:
		var extra: Variant = state.extra_balls
		var awarded: Variant = state.extra_awarded
		if not extra is int or extra < 0 or extra > 2 or not awarded is int or awarded < 0 or awarded > 1:
			return false
		if not state.kickback_ready is bool:
			return false
	if has_bonus:
		var multiplier: Variant = state.bonus_multiplier
		if not state.bonus is int or state.bonus < 0 or state.bonus > MAX_BONUS:
			return false
		if not multiplier is int or multiplier < 1 or multiplier > 5:
			return false
	if not state.table_id is String or state.table_id != table_id:
		return false
	if not state.score is int or state.score < 0:
		return false
	if not state.balls_left is int or state.balls_left < 1 or state.balls_left > MAX_BALLS:
		return false
	if not _valid_timer(state.serve_remaining, 0.7) or not _valid_timer(state.save_remaining, 8.0):
		return false
	if not state.save_armed is bool or not state.sonar_mask is int or not state.depth is int:
		return false
	if state.sonar_mask < 0 or state.sonar_mask > 7 or state.depth < 0:
		return false
	if (table_id == "kernel_panic" or table_id == "dracula" or table_id == "alicia") and (state.sonar_mask != 0 or state.depth != 0):
		return false
	if not state.balls is Array or state.balls.size() > MAX_BALLS:
		return false
	for ball in state.balls:
		if not ball is Dictionary or not _valid_ball(ball):
			return false
	return true


static func _valid_timer(value: Variant, maximum: float) -> bool:
	return value is float and is_finite(value) and value >= 0.0 and value <= maximum


static func _valid_ball(ball: Dictionary) -> bool:
	if ball.size() != BALL_KEYS.size() or not ball.has_all(BALL_KEYS):
		return false
	if not ball.position is Vector2 or not ball.velocity is Vector2:
		return false
	var at: Vector2 = ball.position
	var velocity: Vector2 = ball.velocity
	if not at.is_finite() or at.x < -64.0 or at.x > 784.0 or at.y < 0.0 or at.y > 1800.0:
		return false
	if not velocity.is_finite() or velocity.length_squared() > 10000.0 * 10000.0:
		return false
	return ball.spin is float and is_finite(ball.spin) and ball.rotation is float and is_finite(ball.rotation)
