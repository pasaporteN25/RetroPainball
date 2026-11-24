class_name TableRules
extends Resource
## Números y textos de las reglas de una mesa (S-03 / G-13): puntajes, objetivos, tiempos y mensajes.
## Hay un `.tres` por mesa en `res://resources/rules/<table_id>.tres`; las piezas y reglas lo leen con
## `GameState.active_rules()` (mesa activa) o `GameState.active_rules("<id>")`.
## Los valores por defecto son EXACTAMENTE los que estaban cableados como constantes: sin `.tres`
## (o con uno vacío) el juego se comporta igual que antes. Una mesa nueva solo pisa lo que cambia.
##
## Nombres de modos y mensajes: viven en `messages` (clave -> texto, ver `DEFAULT_MESSAGES`) y se piden con
## `text(clave, {variables})`. `TableTheme.mode_names` queda reservado y sin uso: el tema es solo aspecto.

const DIR := "res://resources/rules/"

## Textos por defecto de todas las claves conocidas. Un `.tres` puede pisar cualquiera en `messages`.
## Variables: {bonus} multiplicador, {award}, {depth}, {stage}, {total}, {count}.
const DEFAULT_MESSAGES := {
	"skill_shot_armed": "SKILL SHOT: AL CARRIL",
	"skill_shot_scored": "SKILL SHOT {award}",
	"kickback": "¡KICKBACK!",
	"kraken_active": "¡KRAKEN ACTIVO!",
	"lock_lit": "LOCK ENCENDIDO",
	"bats_bonus": "MURCIÉLAGOS  BONUS X{bonus}",
	"ball_locked": "BOLA ENCERRADA",
	"midnight_start": "¡MEDIANOCHE!",
	"midnight_end": "AMANECE",
	"balls_released": "BOLAS LIBERADAS",
	"jackpot": "¡JACKPOT!  {award}",
	"size_small": "CHICA",
	"size_big": "GRANDE",
	"size_normal": "TAMAÑO NORMAL",
	"tea_start": "¡TÉ LOCO!",
	"tea_end": "FIN DEL TÉ",
	"process_loaded": "PROCESO {count}/{total}",
	"fork_ready": "FORK() LISTO: AL SAUCER",
	"fork_start": "¡FORK()!  MULTIBOLA",
	"fork_resumed": "MULTIBOLA RETOMADA",
	"fork_end": "SEGFAULT: FIN DE LA MULTIBOLA",
	"sudo_lit": "SUDO ENCENDIDO: AL SAUCER",
}

@export var table_id := "kernel_panic"
@export_group("Comunes")
@export var bumper_points := 100
@export var slingshot_points := 10
## Insertos de los carriles de retorno inferiores.
@export var lane_return_points := 50
@export var skill_shot_award := 5000
## Segundos que dura armado el skill shot.
@export var skill_shot_seconds := 5.0
@export_group("Kernel Panic")
@export var standup_points := 225
## Premio del banco de blancos (StandupBank).
@export var bank_award := 1000
@export var rollover_points := 125
## Premio de los carriles superiores completos.
@export var rollover_award := 1500
## Procesos que hay que cargar (banco de blancos o rollovers completos) para habilitar fork().
@export var fork_processes_needed := 2
## Bolas en juego después de fork() (la que entró al saucer y las que se bifurcan).
@export var fork_balls := 3
## Vueltas del spinner, en multibola, para encender sudo.
@export var sudo_laps := 12
## Jackpot sudo del saucer durante la multibola ({award} en el mensaje).
@export var sudo_jackpot: RuleStage
@export_group("Nautilus")
## Sonares que activan al kraken.
@export var sonar_count := 3
@export var sonar_points := 250
## Puntos del kraken sin activar.
@export var kraken_points := 150
## Metros que baja el submarino por cada jackpot.
@export var depth_step := 1500
## Jackpot del kraken activo ({depth} = profundidad nueva).
@export var kraken_jackpot: RuleStage
@export var chamber_points := 480
@export var chamber_hold_seconds := 0.58
@export var current_points := 360
## Tiempo máximo entre las dos compuertas de la corriente.
@export var current_travel_seconds := 3.0
@export_group("Drácula")
@export var bat_points := 150
## Premio al completar el banco de murciélagos.
@export var bat_bank_award := 1000
## Vueltas Carfax en orden; la última cierra el ciclo ({stage}/{total} en el mensaje).
@export var carfax_stages: Array[RuleStage] = []
@export var carfax_travel_seconds := 3.0
@export var lock_points := 500
@export var coffin_points := 300
@export var coffin_hold_seconds := 0.6
## Bolas encerradas que disparan la Medianoche.
@export var locks_for_midnight := 2
@export var portrait_points := 250
@export var midnight_jackpot_points := 5000
@export_group("Alicia")
## Puntos de cada naipe del banco (con tamaño GRANDE se multiplican por `big_card_multiplier`).
@export var card_points := 150
@export var big_card_multiplier := 2
## Banco de naipes completo: premio, multiplicador y mensaje ("NAIPES COMPLETOS").
@export var card_bank: RuleStage
## Puntos de BEBÉ-ME / CÓMEME cada vez que cambian el tamaño.
@export var size_change_points := 100
## Tamaño de dibujo de los hongos según el estado (NORMAL, CHICA, GRANDE). Solo es aspecto: la física no cambia.
@export var mushroom_draw_scale := PackedFloat32Array([1.0, 1.2, 0.85])
@export var rabbithole_points := 300
@export var rabbithole_hold_seconds := 1.0
@export var alice_lock_points := 500
## Gato de Cheshire: visible y oculto (s) en cada ciclo, premio por golpe y segundos que queda visible tras el golpe.
@export var cheshire_visible_seconds := 4.0
@export var cheshire_hidden_seconds := 3.0
@export var cheshire_points := 1500
@export var cheshire_extend_seconds := 4.0
## Bolas encerradas que disparan Té Loco.
@export var locks_for_tea_party := 2
@export var teapot_points := 250
## Jackpot de la Tetera durante Té Loco ({award} en el mensaje).
@export var tea_jackpot: RuleStage
@export_group("Piezas genéricas (G-10)")
## Saucer/kicker: puntos al retener la bola, segundos que la retiene y velocidad (px/s) con la que la devuelve.
@export var saucer_points := 500
@export var saucer_hold_seconds := 0.6
@export var saucer_kick_speed := 900.0
## Spinner: puntos por vuelta completa y giro (rad/s) por cada px/s de velocidad de la bola.
@export var spinner_lap_points := 25
@export var spinner_spin_per_speed := 0.03
@export_group("Mensajes")
## clave -> texto; ver DEFAULT_MESSAGES.
@export var messages: Dictionary = {}


func _init() -> void:
	# Etapas por defecto (las de hoy). Un .tres guardado las reemplaza al cargarse.
	kraken_jackpot = make_stage(0, 5000, true, "¡JACKPOT!  {depth} m  BONUS X{bonus}")
	var laps: Array[RuleStage] = [
		make_stage(0, 500, false, "CARFAX {stage}/{total}"),
		make_stage(0, 1000, false, "CARFAX {stage}/{total}"),
		make_stage(0, 1500, true, "¡CARFAX!  BONUS X{bonus}")]
	carfax_stages = laps
	card_bank = make_stage(0, 1000, true, "NAIPES COMPLETOS")
	tea_jackpot = make_stage(0, 5000, false, "¡JACKPOT!  {award}")
	sudo_jackpot = make_stage(0, 5000, false, "¡SUDO!  JACKPOT {award}")


static func make_stage(threshold: int, award: int, raise: bool, message: String) -> RuleStage:
	var stage := RuleStage.new()
	stage.threshold = threshold
	stage.award = award
	stage.raise_multiplier = raise
	stage.message = message
	return stage


## Reglas de la mesa `id`. Si no existe devuelve las de Kernel Panic, y si tampoco, las de por defecto.
static func for_table(id: String) -> TableRules:
	for candidate in [id, "kernel_panic"]:
		var path := DIR + str(candidate) + ".tres"
		if ResourceLoader.exists(path):
			var rules := load(path) as TableRules
			if rules:
				return rules
	return TableRules.new()


## Texto de la clave `key` con las variables `{nombre}` reemplazadas. Una clave desconocida devuelve la clave.
func text(key: String, vars: Dictionary = {}) -> String:
	return fill(str(messages.get(key, DEFAULT_MESSAGES.get(key, key))), vars)


## Reemplaza `{nombre}` por `vars["nombre"]` en `template`.
static func fill(template: String, vars: Dictionary) -> String:
	var result := template
	for var_name in vars:
		result = result.replace("{%s}" % var_name, str(vars[var_name]))
	return result


## Índice de la última etapa cuyo `threshold` ya se alcanzó con `progress` (-1 si ninguna). Las etapas
## deben estar ordenadas por umbral creciente.
static func stage_index_for(stages: Array[RuleStage], progress: int) -> int:
	var found := -1
	for i in stages.size():
		if progress >= stages[i].threshold:
			found = i
	return found
