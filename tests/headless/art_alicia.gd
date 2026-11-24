extends SceneTree
## Verifica el arte de Alicia (A-08 / S-09) sin depender de la escena ni de las reglas reales.

const Art := preload("res://scripts/table/alice_art.gd")
const Card := preload("res://scripts/ui/alice_card.gd")
const TitleLayout := preload("res://tests/support/table_title_layout.gd")

class FakeRules extends Node:
	signal size_changed(state: int)
	signal card_flipped(index: int, mask: int)
	signal cards_completed
	signal lock_lit_changed(lit: bool)
	signal ball_locked(count: int)
	signal cheshire_changed(visible: bool)
	signal cheshire_hit
	signal tea_party_started
	signal tea_party_ended
	var size_state := 0
	var cards_mask := 0
	var lock_lit := false
	var locked_balls := 0
	var tea_party := false
	var cheshire_visible := true

## Pieza de prueba: dibuja todas las funciones de AliceVisuals en todos sus estados.
class PiecesControl extends Node2D:
	func _draw() -> void:
		for suit in 4:
			for flipped in [false, true]:
				AliceVisuals.draw_card(self, suit, flipped, Vector2(44, 62))
				AliceVisuals.draw_card(self, suit, flipped, Vector2(1, 1))
		for kind in [AliceVisuals.SIZE_DRINK, AliceVisuals.SIZE_EAT]:
			for active in [false, true]:
				AliceVisuals.draw_size_target(self, kind, active, 24.0)
		for v in [-0.5, 0.0, 0.01, 0.3, 0.7, 1.0, 2.0]:
			AliceVisuals.draw_cheshire(self, 30.0, v)
		for f in [0.0, 0.5, 1.0]:
			AliceVisuals.draw_mushroom(self, 36.0, f)
		for lit in [false, true]:
			AliceVisuals.draw_teapot(self, 55.0, lit)
			AliceVisuals.draw_rabbithole(self, 40.0, lit)
		AliceVisuals.draw_mushroom(self, 8.0, 0.0)

class CardControl extends Control:
	func _draw() -> void:
		Card.draw(self, Rect2(0, 0, 400, 200))
		Card.draw(self, Rect2(0, 0, 300, 220))

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_check(load("res://scripts/table/alice_art.gd") != null and load("res://scripts/table/alice_visuals.gd") != null
		and load("res://scripts/ui/alice_card.gd") != null, "los 3 scripts cargan")
	for method in ["draw_card", "draw_size_target", "draw_cheshire", "draw_mushroom", "draw_teapot", "draw_rabbithole"]:
		_check(_has_static(method), "AliceVisuals.%s existe" % method)
	var parent := Node2D.new()
	root.add_child(parent)
	var art := Art.new()
	parent.add_child(art)
	_test_title(art)
	art.pulse_score()
	art.flash_jackpot()
	art.set_ball_save_fraction(2.0)
	_check(art._save_fraction == 1.0, "API y límite de salvabolas sin AliceRules")
	await process_frame
	await process_frame
	var art_ref: WeakRef = weakref(art)
	parent.queue_free()
	await process_frame
	_check(art_ref.get_ref() == null, "arte liberado sin nodos huérfanos")
	# Con reglas falsas: lee el estado inicial y reacciona a las señales.
	parent = Node2D.new()
	root.add_child(parent)
	var rules := FakeRules.new()
	rules.name = "AliceRules"
	rules.size_state = 2
	parent.add_child(rules)
	art = Art.new()
	parent.add_child(art)
	_check(art._size_state == 2, "lee el tamaño inicial de las reglas")
	rules.size_changed.emit(1)
	_check(art._size_state == 1, "size_changed cambia el marco")
	rules.size_changed.emit(7)
	_check(art._size_state == 2, "tamaño fuera de rango se acota")
	rules.lock_lit_changed.emit(true)
	rules.tea_party_started.emit()
	rules.cards_completed.emit()
	rules.ball_locked.emit(1)
	rules.cheshire_hit.emit()
	rules.cheshire_changed.emit(false)
	rules.card_flipped.emit(0, 1)
	_check(art._lock_lit and art._tea_party, "lock y Té Loco activan el arte")
	await process_frame
	rules.tea_party_ended.emit()
	rules.lock_lit_changed.emit(false)
	rules.size_changed.emit(0)
	_check(not art._lock_lit and not art._tea_party and art._size_state == 0, "todo se apaga")
	for i in 40:
		await process_frame
	_check(art._redraw_elapsed < 1.0, "la capa dinámica sigue su ritmo")
	var pieces := PiecesControl.new()
	var card := CardControl.new()
	root.add_child(pieces)
	root.add_child(card)
	pieces.queue_redraw()
	card.queue_redraw()
	await process_frame
	await process_frame
	art_ref = weakref(art)
	var card_ref: WeakRef = weakref(card)
	parent.queue_free()
	card.queue_free()
	pieces.queue_free()
	await process_frame
	_check(art_ref.get_ref() == null and card_ref.get_ref() == null, "arte y tarjeta liberados")
	print("Arte Alicia: %d fallos" % failures)
	quit(1 if failures else 0)

func _test_title(art: Node2D) -> void:
	var scene := (load("res://scenes/alicia.tscn") as PackedScene).instantiate()
	var wall := scene.get_node("Table/OuterWall") as Node2D
	var heading := TitleLayout.text_bounds(art._font, Art.TITLE, Art.TITLE_AT, Art.TITLE_SIZE, 5.0)
	var subtitle := TitleLayout.text_bounds(art._font, Art.SUBTITLE, Art.SUBTITLE_AT, Art.SUBTITLE_SIZE, 5.0)
	_check(TitleLayout.title_fits(art, wall, heading) and TitleLayout.title_fits(art, wall, subtitle),
		"el título y el subtítulo entran en pantalla vertical por dentro del arco")
	for label in ["CHICA", "GRANDE"]:
		var size_label := TitleLayout.text_bounds(art._font, label, Art.SIZE_LABEL_AT, Art.SIZE_LABEL_SIZE, 4.0)
		_check(TitleLayout.title_fits(art, wall, size_label), "%s entra por dentro del arco" % label)
	scene.free()

func _has_static(method: String) -> bool:
	for entry in (AliceVisuals as Script).get_script_method_list():
		if entry.name == method:
			return true
	return false

func _check(ok: bool, description: String) -> void:
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		failures += 1
