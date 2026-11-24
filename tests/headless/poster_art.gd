extends SceneTree
## U-04: pasa los cuatro pósters por _draw() y reconstruye su grilla sin depender de la GPU.

const Art := preload("res://scripts/ui/poster_art.gd")


class PosterCanvas extends Node2D:
	var table_ids: Array[String] = []
	var drawn_ids: Array[String] = []
	var time := 0.0

	func _draw() -> void:
		drawn_ids.clear()
		for i in table_ids.size():
			Art.draw(self, table_ids[i], Rect2(7.5 + i * 105.0, 9.0, 101.5, 87.25), time)
			drawn_ids.append(table_ids[i])


var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	var table_ids: Array[String] = [state.KERNEL_PANIC, state.NAUTILUS, state.DRACULA, state.ALICIA]
	var canvas := PosterCanvas.new()
	canvas.table_ids.assign(table_ids)
	canvas.table_ids.append("mesa_inexistente")
	root.add_child(canvas)
	await process_frame
	await process_frame
	_check(canvas.drawn_ids == canvas.table_ids, "_draw() completa las cuatro mesas y el id desconocido")

	canvas.time = 1.8
	canvas.drawn_ids.clear()
	canvas.queue_redraw()
	await process_frame
	await process_frame
	_check(canvas.drawn_ids == canvas.table_ids, "los mismos pósters se redibujan en otro instante")

	var silhouettes: Array[PackedByteArray] = []
	for id in table_ids:
		var silhouette := _check_grid(id)
		_check(not silhouettes.has(silhouette), "%s tiene una silueta propia" % id)
		silhouettes.append(silhouette)

	canvas.free()
	print("Pósters: %d fallos" % failures)
	quit(1 if failures else 0)


func _check_grid(id: String) -> PackedByteArray:
	var grid := Rect2i(Vector2i.ZERO, Art.GRID)
	var pixels := PackedByteArray()
	pixels.resize(grid.get_area())
	var silhouette := pixels.duplicate()
	var palette: Array[Color] = Art.PALETTES[id]
	var layers := Art._layers_for(id)
	var colors_used: Dictionary[Color, bool] = {palette[0]: true}
	var in_bounds := true
	for shade in range(1, layers.size()):
		for run: Rect2i in layers[shade]:
			if not grid.encloses(run):
				in_bounds = false
				continue
			colors_used[palette[shade]] = true
			for y in range(run.position.y, run.end.y):
				for x in range(run.position.x, run.end.x):
					var index := y * grid.size.x + x
					pixels[index] = shade
					silhouette[index] = 1
	var encoded: String = Art.PIXELS[id]
	var rows := encoded.strip_edges().split("\n")
	var has_grid_size := rows.size() == grid.size.y
	for row in rows:
		has_grid_size = has_grid_size and row.length() == grid.size.x
	# Los tonos son bytes 0..7; sumales '0' para compararlos con el dibujo fuente.
	for i in pixels.size():
		pixels[i] += 48
	var expected := "".join(rows)
	_check(has_grid_size and in_bounds and pixels.get_string_from_ascii() == expected,
		"%s usa una grilla completa de 48×56" % id)
	_check(colors_used.size() >= 2 and palette.size() <= 8, "%s usa %d colores" % [id, colors_used.size()])
	_check(silhouette.count(1) > 0 and silhouette.count(0) > 0, "%s tiene arte y fondo" % id)
	return silhouette


func _check(ok: bool, message: String) -> void:
	print(("OK: " if ok else "FALLÓ: ") + message)
	if not ok:
		failures += 1
