extends Node2D
## Destellos sobre cada pieza del grupo que acaba de completarse.

const TableBurst := preload("res://scripts/fx/table_burst.gd")


func _ready() -> void:
	for bank_name in ["StandupBank", "RolloverBank"]:
		var bank := get_parent().get_node(bank_name)
		bank.completed.connect(celebrate.bind(bank))


func celebrate(_award: int, bank: Node) -> void:
	for path in bank.members:
		var piece := bank.get_node_or_null(path) as Node2D
		if piece == null:
			continue
		var burst := TableBurst.new()
		burst.setup(to_local(piece.global_position), piece.tint, 18.0, 8)
		add_child(burst)
