extends SceneTree
## F1a: test chico del bot de playtesting. El experto juega 50 bolas en Kernel Panic y tiene que
## superar bien al bot al azar (el control); y con la misma semilla el resultado tiene que ser el
## mismo (si no, las comparaciones antes/después de F1c no sirven).
##
## Cada corrida es un proceso aparte de tools/playtest/run.gd con `--fixed-fps 60` (así va ~25 veces
## más rápido que tiempo real); los tres corren en paralelo.

const BALLS := 50
const SEED := 11
const MIN_RATIO := 1.5
const TIMEOUT := 400.0

var _checks := 0
var _errors := 0
var _dir := "user://test_playtest_bot_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var abs_dir := ProjectSettings.globalize_path(_dir)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var jobs := {"experto": "a", "azar": "b", "experto2": "c"}
	var pids := {}
	for key: String in jobs:
		var bot := key.trim_suffix("2")
		var args := PackedStringArray(["--headless", "--fixed-fps", "60", "--path", ProjectSettings.globalize_path("res://"),
				"-s", "res://tools/playtest/run.gd", "--", "table=kernel_panic", "bot=%s" % bot, "balls=%d" % BALLS,
				"seed=%d" % SEED, "out=%s" % abs_dir.path_join(jobs[key]), "tag="])
		pids[key] = OS.create_process(OS.get_executable_path(), args)
		_check(int(pids[key]) > 0, "%s: arranca el proceso" % key)
	var waited := 0.0
	while waited < TIMEOUT and _any_running(pids):
		await create_timer(1.0).timeout
		waited += 1.0
	_check(not _any_running(pids), "las corridas terminan antes de %d s" % int(TIMEOUT))
	var expert := _load(abs_dir.path_join("a/kernel_panic_experto.jsonl"))
	var chance := _load(abs_dir.path_join("b/kernel_panic_azar.jsonl"))
	var again := _load(abs_dir.path_join("c/kernel_panic_experto.jsonl"))
	_check(expert.balls >= BALLS and chance.balls >= BALLS, "ambos bots juegan %d bolas (%d / %d)" % [BALLS, expert.balls, chance.balls])
	_check(not expert.cut and not chance.cut, "ninguna sesión se cortó por el tope de tiempo")
	_check(expert.mean > chance.mean * MIN_RATIO, "el experto supera al azar por x%.1f (%.0f vs %.0f puntos por bola)" % [MIN_RATIO, expert.mean, chance.mean])
	_check(expert.balls == again.balls and is_equal_approx(expert.mean, again.mean), "misma semilla, mismo resultado (%.0f vs %.0f)" % [expert.mean, again.mean])
	_remove(abs_dir)
	print("Bot de playtest: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)


func _any_running(pids: Dictionary) -> bool:
	for key: String in pids:
		if int(pids[key]) > 0 and OS.is_process_running(int(pids[key])):
			return true
	return false


## {balls, mean, cut} de un .jsonl (ceros si falta o está incompleto).
func _load(path: String) -> Dictionary:
	var result := {"balls": 0, "mean": 0.0, "cut": true}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var total := 0.0
	var count := 0
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty():
			continue
		var row: Variant = JSON.parse_string(line)
		if not row is Dictionary:
			continue
		if row.get("type", "") == "ball":
			total += float(row.points)
			count += 1
		elif row.get("type", "") == "summary":
			result.cut = bool(row.cut)
	result.balls = count
	result.mean = total / maxi(1, count)
	return result


func _remove(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_remove(dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok
