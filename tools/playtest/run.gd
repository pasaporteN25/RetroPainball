extends SceneTree
## Runner del playtesting (F1a). Un proceso = una mesa, un bot y una semilla. Para varios en
## paralelo, usar tools/playtest.sh.
##
## Uso:  godot --headless --path . -s tools/playtest/run.gd -- table=kernel_panic bot=medio \
##           balls=200 seed=1 speed=1 out=build/playtest/2026-11-24 [tag=_s1]
## Escribe <out>/<mesa>_<bot><tag>.jsonl: una línea por bola, una por partida y al final "summary".

const Session := preload("res://tools/playtest/session.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var table_id := _arg("table", "kernel_panic")
	var skill := _arg("bot", "medio")
	var balls := int(_arg("balls", "100"))
	var seed_value := int(_arg("seed", "1"))
	var speed := float(_arg("speed", "1"))
	var out := _arg("out", "build/playtest/%s" % Time.get_date_string_from_system())
	var tag := _arg("tag", "")
	if not Session.TABLES.has(table_id) or not Session.Bot.PROFILES.has(skill) and skill != "azar":
		printerr("Mesa o bot desconocido: %s / %s" % [table_id, skill])
		quit(2)
		return
	var session := Session.new(self)
	session.verbose = _arg("verbose", "0") == "1"
	session.naive = _arg("naive", "0") == "1"
	var result: Dictionary = await session.play(table_id, skill, balls, seed_value, speed)
	var dir := out if out.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("%s_%s%s.jsonl" % [table_id, skill, tag])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("No se pudo escribir %s" % path)
		quit(1)
		return
	for record: Dictionary in result.records:
		file.store_line(JSON.stringify(record))
	file.store_line(JSON.stringify(result.summary))
	file.close()
	var s: Dictionary = result.summary
	print("%s/%s semilla %d: %d bolas, %d partidas, %.0f s de juego en %.1f s reales -> %s" % [
		table_id, skill, seed_value, s.balls, s.games, s.game_seconds, s.wall_seconds, path])
	quit(0)


func _arg(arg_name: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(arg_name + "="):
			return arg.trim_prefix(arg_name + "=")
	return fallback
