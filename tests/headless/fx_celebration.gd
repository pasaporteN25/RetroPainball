extends SceneTree
## Verifica las celebraciones y el indicador en las dos mesas, sin usar guardados reales.

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var prefix := "user://test_fx_celebration_%d" % OS.get_process_id()
	state.save_directory = prefix
	state.record_path = prefix + ".cfg"
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for path in ["res://scenes/main.tscn", "res://scenes/nautilus.tscn"]:
		var game := (load(path) as PackedScene).instantiate()
		root.add_child(game)
		var lamps = game.get_node("Table/BonusLamps")
		_check(lamps.lit_count == 1, "la partida comienza con una luz")
		for i in range(2, 6):
			state.raise_multiplier(false)
			await process_frame
			await process_frame
			_check(lamps.lit_count == i, "el indicador sigue el multiplicador x%d" % i)
		state.bonus = 100
		state.award_bonus()
		_check(lamps.lit_count == 0, "cobrar el bonus apaga las luces")
		await process_frame
		_check(lamps.lit_count == 0, "las luces permanecen apagadas después del cobro")
		state.raise_multiplier(false)
		await process_frame
		_check(lamps.lit_count == 2, "las luces vuelven al subir el multiplicador")
		state.start_game()
		_check(lamps.lit_count == 1, "una partida nueva restablece el indicador")
		var layout := game.get_node_or_null("Table/KernelLayout")
		if layout:
			var celebration := layout.get_node("Celebration")
			for bank_name in ["StandupBank", "RolloverBank"]:
				var bank = layout.get_node(bank_name)
				bank.completed.emit(bank.award)
				_check(celebration.get_child_count() == bank.members.size(), "%s crea una ráfaga por pieza" % bank_name)
				await create_timer(0.4).timeout
				_check(celebration.get_child_count() == 0, "las ráfagas se liberan solas")
		game.queue_free()
		await process_frame
		await process_frame
		_check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphans, "la mesa no deja nodos huérfanos")
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(prefix)):
		for file in DirAccess.get_files_at(prefix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix.path_join(file)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(prefix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.record_path))
	print("Celebraciones: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(ok: bool, description: String) -> void:
	_checks += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
