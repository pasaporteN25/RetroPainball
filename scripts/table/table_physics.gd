class_name TablePhysics
extends Resource
## Números de física de la mesa, para afinarlos sin tocar código. Los valores por
## defecto son EXACTAMENTE los que el juego usaba antes de existir este Resource.
## Las piezas piden `TablePhysics.active()`: si nadie cargó uno, se usa el .tres por
## defecto y, si ni eso existe, una instancia con los valores de este script.

const DEFAULT_PATH := "res://resources/table_physics.tres"

static var _active: TablePhysics

@export_group("Mundo")
## Gravedad 2D (px/s^2). Equivale a physics/2d/default_gravity de project.godot.
@export var gravity := 1600.0

@export_group("Bola")
@export var ball_radius := 16.0
@export var ball_bounce := 0.2
@export var ball_friction := 0.25
@export var ball_max_speed := 4200.0

@export_group("Flippers")
## Velocidad de subida y bajada, en radianes por segundo.
@export var flipper_up_speed := 26.0
@export var flipper_down_speed := 16.0
@export var flipper_bounce := 0.0
@export var flipper_friction := 0.8

@export_group("Bumpers y slingshots")
@export var bumper_bounce := 0.0
@export var bumper_kick_speed := 1300.0
## Fracción de la velocidad tangencial que conserva la bola al chocar un bumper.
@export var bumper_tangent_keep := 0.5
@export var slingshot_bounce := 0.25
@export var slingshot_kick_speed := 1000.0

@export_group("Lanzador")
@export var plunger_min_speed := 1200.0
## Velocidad de salida con carga completa (la fuerza máxima del lanzador).
@export var plunger_max_speed := 3000.0


## Física vigente: la que cargó la mesa, o el .tres por defecto, o los valores del script.
static func active() -> TablePhysics:
	if _active == null:
		if ResourceLoader.exists(DEFAULT_PATH):
			_active = load(DEFAULT_PATH) as TablePhysics
		if _active == null:
			_active = TablePhysics.new()
	return _active


## La mesa fija la física vigente (null vuelve a los valores por defecto).
static func use(physics: TablePhysics) -> void:
	_active = physics
