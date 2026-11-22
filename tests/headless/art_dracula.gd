extends SceneTree
## Verifica arte y contrato sin depender de la escena ni de las reglas reales.

const Art := preload("res://scripts/table/dracula_art.gd")
const Card := preload("res://scripts/ui/dracula_card.gd")

class FakeRules extends Node:
	signal bats_changed(hit: int)
	signal lock_lit_changed(lit: bool)
	signal ball_locked(count: int)
	signal midnight_started
	signal midnight_ended
	signal carfax_scored(stage: int)
	var locks_lit := false
	var locked_balls := 0
	var midnight := false
	var bats_hit := 0
	var carfax_stage := 0

class CardControl extends Control:
	func _draw() -> void:
		Card.draw(self, Rect2(0, 0, 400, 200))

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	var art := Art.new()
	parent.add_child(art)
	art.pulse_score()
	art.flash_jackpot()
	art.set_ball_save_fraction(2.0)
	_check(art._save_fraction == 1.0, "API y límite de salvabolas sin reglas")
	art.queue_redraw()
	await process_frame
	var art_ref: WeakRef = weakref(art)
	parent.queue_free()
	await process_frame
	_check(art_ref.get_ref() == null, "arte liberado sin nodos huérfanos")
	parent = Node2D.new()
	root.add_child(parent)
	var rules := FakeRules.new()
	rules.name = "DraculaRules"
	parent.add_child(rules)
	art = Art.new()
	parent.add_child(art)
	rules.bats_changed.emit(3)
	rules.lock_lit_changed.emit(true)
	rules.ball_locked.emit(1)
	rules.midnight_started.emit()
	rules.carfax_scored.emit(2)
	_check(art._midnight and art._lock_lit, "Medianoche y lock activan el arte")
	await process_frame
	rules.midnight_ended.emit()
	rules.lock_lit_changed.emit(false)
	_check(not art._midnight and not art._lock_lit, "Medianoche y lock se apagan")
	var card := CardControl.new()
	root.add_child(card)
	card.queue_redraw()
	await process_frame
	var card_ref: WeakRef = weakref(card)
	art_ref = weakref(art)
	parent.queue_free()
	card.queue_free()
	await process_frame
	_check(art_ref.get_ref() == null and card_ref.get_ref() == null, "arte y tarjeta liberados")
	print("Arte Drácula: %d fallos" % failures)
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		failures += 1
