extends SceneTree

const Hint := preload("res://scripts/ui/first_run_hint.gd")
var path := "user://test_hint_%d/settings.cfg" % OS.get_process_id()
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var baseline := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var hint := Hint.new()
	hint.settings_path = path
	root.add_child(hint)
	_check(hint._panel != null and hint._panel.visible, "muestra la pista inicial")
	hint.on_launched(1.0)
	_check(not hint._panel.visible, "el lanzamiento oculta la pista")
	hint.free()
	var again := Hint.new()
	again.settings_path = path
	root.add_child(again)
	_check(again._panel == null, "no vuelve a mostrarla")
	again.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var timed := Hint.new()
	timed.settings_path = path
	timed.duration = 0.01
	root.add_child(timed)
	timed._process(0.02)
	_check(not timed._panel.visible, "el tiempo oculta la pista")
	timed.free()
	_check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == baseline, "sin nodos huérfanos")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok: failures += 1
