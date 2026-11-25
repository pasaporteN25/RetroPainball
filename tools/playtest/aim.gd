extends RefCounted
## Qué le conviene pegarle a la bola ahora mismo en cada mesa (F1 / puntería del bot).
## Lee el estado de las reglas y de las piezas (lámparas y objetivos encendidos) y devuelve una
## lista de blancos `{pos, w}`: la posición en coordenadas de la mesa y cuánto vale golpearlo.
## Solo LEE: no toca reglas, física ni mesas. Si un nodo no existe (otra mesa), se lo saltea.

## Valor base de los bumpers: mantienen la bola arriba aunque no haya nada encendido.
const BUMPER_W := 0.3

var _table: Node2D
var _kind := ""
var _bumpers: Array[Vector2] = []


func _init(table: Node2D) -> void:
	_table = table
	if table.has_node("KernelRules"):
		_kind = "kernel"
	elif table.has_node("DepthMission"):
		_kind = "nautilus"
	elif table.has_node("DraculaRules"):
		_kind = "dracula"
	elif table.has_node("AliceRules"):
		_kind = "alicia"
	for node_name in ["BumperLeft", "BumperRight", "BumperBottom"]:
		if table.has_node(node_name):
			_bumpers.append(table.get_node(node_name).position)


## Blancos activos, del más al menos valioso no necesariamente: el que decide es quien los pondera.
func wanted() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for p in _bumpers:
		list.append({"pos": p, "w": BUMPER_W})
	match _kind:
		"kernel":
			_kernel(list)
		"nautilus":
			_nautilus(list)
		"dracula":
			_dracula(list)
		"alicia":
			_alicia(list)
	return list


func _add(list: Array[Dictionary], path: String, w: float) -> void:
	var node := _table.get_node_or_null(path)
	if node is Node2D:
		list.append({"pos": _table.to_local((node as Node2D).global_position), "w": w})


func _kernel(list: Array[Dictionary]) -> void:
	var rules: Node = _table.get_node("KernelRules")
	if rules.fork_ready or (rules.multiball and rules.sudo_lit):
		_add(list, "KernelLayout/Fork", 4.0)
	if rules.multiball and not rules.sudo_lit:
		_add(list, "KernelLayout/Sudo", 3.0)
	else:
		_add(list, "KernelLayout/Sudo", 0.7)
	# Banco de blancos y rollovers: lo que todavía está apagado es lo que carga procesos.
	for path in ["KernelLayout/StandupLeft", "KernelLayout/StandupRight"]:
		var node := _table.get_node_or_null(path)
		if node and not node.activated:
			_add(list, path, 1.6)
	for path in ["KernelLayout/Boot", "KernelLayout/BusLeft", "KernelLayout/BusRight"]:
		var node := _table.get_node_or_null(path)
		if node and not node.lit:
			_add(list, path, 1.3)


func _nautilus(list: Array[Dictionary]) -> void:
	var mission: Node = _table.get_node("DepthMission")
	if mission.is_kraken_active():
		_add(list, "Kraken", 4.0)
	else:
		_add(list, "Kraken", 0.4)
		var names := ["Port", "Bow", "Starboard"]
		for i in names.size():
			if not (int(mission.sonar_mask) & (1 << i)):
				_add(list, "Sonars/%s" % names[i], 1.8)
	_add(list, "PressureChamber", 0.8)


func _dracula(list: Array[Dictionary]) -> void:
	var rules: Node = _table.get_node("DraculaRules")
	if rules.locks_lit:
		_add(list, "Coffin", 3.5)
	if rules.midnight:
		_add(list, "Portrait", 4.0)
	else:
		_add(list, "Portrait", 0.5)
	for path in ["Bats/BatLeft", "Bats/BatMid", "Bats/BatRight"]:
		var node := _table.get_node_or_null(path)
		if node and not node.activated:
			_add(list, path, 1.6)
	_add(list, "Carfax/GateIn", 0.8)


func _alicia(list: Array[Dictionary]) -> void:
	var rules: Node = _table.get_node("AliceRules")
	if rules.lock_lit:
		_add(list, "Rabbithole", 3.5)
	if rules.tea_party:
		_add(list, "Teapot", 4.0)
	else:
		_add(list, "Teapot", 0.5)
	for i in 4:
		var node := _table.get_node_or_null("Cards/Card%d" % i)
		if node and not node.flipped:
			_add(list, "Cards/Card%d" % i, 1.6)
	for path in ["Size/DrinkMe", "Size/EatMe"]:
		var node := _table.get_node_or_null(path)
		if node and not node.active:
			_add(list, path, 0.8)
	if rules.cheshire_visible:
		_add(list, "Cheshire", 1.0)
