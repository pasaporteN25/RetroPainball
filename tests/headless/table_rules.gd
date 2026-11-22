extends SceneTree
## S-03 / G-13: cada mesa tiene su TableRules válido, los valores por defecto son los de siempre y
## cambiar un valor del Resource cambia el puntaje o el mensaje real (Drácula y Nautilus con piezas reales).

const IDS := ["kernel_panic", "nautilus", "dracula"]
var _game: Node
var _checks := 0
var _errors := 0
var _scratch := "user://test_table_rules_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var _messages: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node("GameState")
	_game.record_path = _scratch.path_join("records.cfg")
	_game.save_directory = ""
	_game.message.connect(func(text: String) -> void: _messages.append(text))
	_test_resources()
	_test_stages_and_text()
	await _test_dracula()
	await _test_nautilus_mission()
	_finish()


func _test_resources() -> void:
	for id in IDS:
		var path := "res://resources/rules/%s.tres" % id
		_check(ResourceLoader.exists(path), "%s tiene su .tres de reglas" % id)
		var rules := _game.active_rules(id) as TableRules
		_check(rules != null and rules.table_id == id, "%s: active_rules devuelve sus reglas" % id)
		var positive: bool = rules.bumper_points > 0 and rules.slingshot_points > 0 and rules.skill_shot_award > 0 \
			and rules.standup_points > 0 and rules.bank_award > 0 and rules.sonar_count > 0 and rules.depth_step > 0 \
			and rules.locks_for_midnight > 0 and rules.carfax_travel_seconds > 0.0 and rules.coffin_hold_seconds > 0.0
		_check(positive, "%s: puntajes, objetivos y tiempos válidos" % id)
		_check(rules.carfax_stages.size() == 3 and rules.kraken_jackpot != null, "%s: etapas cargadas" % id)
		for key in TableRules.DEFAULT_MESSAGES:
			_check(not rules.text(key, {"bonus": 2, "award": 1, "depth": 1}).contains("{"), "%s: mensaje %s sin variables sin resolver" % [id, key])
	_check(_game.active_rules("no_existe").table_id == "kernel_panic", "id desconocido usa Kernel Panic")
	var plain := TableRules.new()
	_check(plain.bumper_points == 100 and plain.slingshot_points == 10 and plain.standup_points == 225
		and plain.bank_award == 1000 and plain.rollover_award == 1500 and plain.chamber_points == 480
		and plain.current_points == 360 and plain.lock_points == 500 and plain.midnight_jackpot_points == 5000,
		"los valores por defecto son los de antes")
	var dracula: TableRules = _game.active_rules("dracula")
	_check(dracula.carfax_stages[0].award == 500 and dracula.carfax_stages[1].award == 1000
		and dracula.carfax_stages[2].award == 1500 and dracula.carfax_stages[2].raise_multiplier, "Carfax: 500, 1000, 1500 y multiplicador")


func _test_stages_and_text() -> void:
	var rules := TableRules.new()
	_check(rules.text("lock_lit") == "LOCK ENCENDIDO" and rules.text("skill_shot_scored", {"award": 7}) == "SKILL SHOT 7",
		"text() usa el mensaje por defecto y reemplaza variables")
	rules.messages = {"lock_lit": "LOCK X"}
	_check(rules.text("lock_lit") == "LOCK X" and rules.text("clave_rara") == "clave_rara", "messages pisa el texto; clave desconocida se devuelve")
	var stages: Array[RuleStage] = [TableRules.make_stage(0, 100, false, ""), TableRules.make_stage(5, 200, true, ""),
		TableRules.make_stage(12, 300, false, "")]
	_check(TableRules.stage_index_for(stages, 0) == 0 and TableRules.stage_index_for(stages, 7) == 1
		and TableRules.stage_index_for(stages, 99) == 2 and TableRules.stage_index_for(stages, -1) == -1, "stage_index_for elige la etapa por umbral")


func _test_dracula() -> void:
	if not _check(change_scene_to_file("res://scenes/dracula.tscn") == OK, "abre Drácula"):
		return
	await scene_changed
	await process_frame
	_game.start_game()
	var rules: TableRules = _game.active_rules()
	var table := current_scene.get_node("Table")
	var dracula_rules := table.get_node("DraculaRules")
	var bat := table.get_node("Bats").get_child(0)
	var saved := rules.bat_points
	var before: int = _game.score
	bat.strike()
	_check(_game.score == before + saved, "el murciélago paga lo que dice TableRules")
	rules.bat_points = 777
	before = _game.score
	bat.strike()
	_check(_game.score == before + 777, "cambiar bat_points cambia el puntaje real")
	rules.bat_points = saved
	# Carfax con etapas editadas: premio y mensaje salen del Resource.
	var first: RuleStage = rules.carfax_stages[0]
	var old_award := first.award
	var old_message := first.message
	first.award = 888
	first.message = "VUELTA {stage} DE {total}"
	_messages.clear()
	before = _game.score
	dracula_rules._on_carfax_completed(Vector2.ZERO)
	_check(_game.score == before + 888 and _messages.back() == "VUELTA 1 DE 3", "la etapa de Carfax manda el premio y el mensaje")
	first.award = old_award
	first.message = old_message
	rules.messages = {"midnight_start": "MEDIANOCHE X"}
	_messages.clear()
	dracula_rules.start_midnight()
	_check(_messages.back() == "MEDIANOCHE X", "el nombre del modo sale de TableRules.messages")
	rules.messages = {}
	var portrait := table.get_node("Portrait")
	rules.midnight_jackpot_points = 1234
	before = _game.score
	dracula_rules._on_portrait_struck(Vector2.ZERO)
	_check(_game.score == before + 1234, "el jackpot de la Medianoche sale de TableRules")
	rules.midnight_jackpot_points = 5000
	_check(portrait != null, "el retrato existe")


func _test_nautilus_mission() -> void:
	_game.select_table("nautilus")
	var rules: TableRules = _game.active_rules()
	_check(rules.table_id == "nautilus", "la mesa activa es Nautilus")
	_game.start_game()
	var mission: Node = (load("res://scripts/table/depth_mission.gd") as GDScript).new()
	root.add_child(mission)
	mission.on_sonar(0, Vector2.ZERO)
	var before: int = _game.score
	rules.sonar_count = 2
	mission.on_sonar(1, Vector2.ZERO)
	_check(_game.score == before + rules.sonar_points and mission.is_kraken_active(), "sonar_count cambia cuántos sonares activan al kraken")
	rules.sonar_count = 3
	mission.restore(0b111, 0)
	rules.kraken_jackpot.award = 4321
	rules.depth_step = 100
	before = _game.score
	mission.on_kraken(Vector2.ZERO)
	_check(_game.score == before + 4321 and mission.depth == 100, "el jackpot y el escalón de profundidad salen de TableRules")
	rules.kraken_jackpot.award = 5000
	rules.depth_step = 1500
	mission.queue_free()


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_errors += 1
	return ok


func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch.path_join("records.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_scratch))
	print("TableRules: %d controles / %d fallos" % [_checks, _errors])
	quit(0 if _errors == 0 else 1)
