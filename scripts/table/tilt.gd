extends RefCounted
## G-04: lógica pura del nudge/tilt (sin nodos ni input, para poder testearla).
## Cada empujón suma "calor"; el calor decae con el tiempo. Con poco calor el empujón
## pasa limpio, con calor medio hay aviso y con calor alto es TILT hasta que se pierda la bola.

enum Result { IGNORED, NUDGE, WARNING, TILT }

## Calor que suma cada empujón.
@export var nudge_heat := 0.35
## Desde este calor cada empujón avisa ("CUIDADO").
@export var warning_heat := 0.6
## Desde este calor es TILT.
@export var tilt_heat := 1.0
## Calor que se enfría por segundo.
@export var decay_per_second := 0.3
## Segundos mínimos entre dos empujones (evita que un solo gesto cuente varias veces).
@export var nudge_cooldown := 0.3
## Cambio brusco de aceleración (m/s², sin la gravedad) que cuenta como sacudida.
@export var shake_threshold := 12.0
## Qué tan rápido sigue el filtro de gravedad a la lectura del acelerómetro (0..1 por lectura).
@export_range(0.01, 1.0) var gravity_follow := 0.1

var heat := 0.0
var tilted := false
var _cooldown := 0.0
var _gravity := Vector3.ZERO
var _has_gravity := false


## Enfría el calor y el enfriamiento entre empujones.
func tick(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	heat = maxf(0.0, heat - decay_per_second * delta)


## Registra un empujón. En TILT, o durante el enfriamiento, no hace nada.
func register_nudge() -> Result:
	if tilted or _cooldown > 0.0:
		return Result.IGNORED
	_cooldown = nudge_cooldown
	heat += nudge_heat
	if heat >= tilt_heat:
		tilted = true
		return Result.TILT
	return Result.WARNING if heat >= warning_heat else Result.NUDGE


## Vuelve a la normalidad (bola nueva o partida nueva).
func reset() -> void:
	heat = 0.0
	tilted = false
	_cooldown = 0.0


## Alimenta una lectura del acelerómetro; true si fue una sacudida. Un teléfono quieto
## (aunque esté inclinado) o en la PC (lectura cero) nunca dispara.
func feed_accelerometer(accel: Vector3) -> bool:
	if accel == Vector3.ZERO:
		return false
	if not _has_gravity:
		_gravity = accel
		_has_gravity = true
		return false
	var jerk := (accel - _gravity).length()
	_gravity = _gravity.lerp(accel, gravity_follow)
	return jerk >= shake_threshold
