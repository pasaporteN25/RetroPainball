extends SceneTree
## Valida resources/credits.json: cada entrada con título, autor, licencia permitida y fuente.

const PATH := "res://resources/credits.json"
const KINDS: Array[String] = ["music", "font", "art"]
## Solo licencias libres de uso comercial y con derivadas permitidas (nada NC ni ND).
const ALLOWED: Array[String] = ["CC0", "CC-BY", "CC-BY-SA", "OFL", "MIT", "public-domain", "original"]
const REQUIRED: Array[String] = ["id", "kind", "title", "author", "license", "source"]

var failures := 0


func _initialize() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("entries")) != TYPE_ARRAY:
		_fail("credits.json no es un objeto con 'entries'")
		_finish()
		return
	var ids := {}
	for entry in data["entries"]:
		if typeof(entry) != TYPE_DICTIONARY:
			_fail("entrada que no es objeto")
			continue
		var label := str(entry.get("id", "?"))
		for key in REQUIRED:
			if str(entry.get(key, "")).strip_edges() == "":
				_fail("%s: falta '%s'" % [label, key])
		if ids.has(label):
			_fail("%s: id repetido" % label)
		ids[label] = true
		if not KINDS.has(str(entry.get("kind", ""))):
			_fail("%s: kind inválido" % label)
		if not ALLOWED.has(str(entry.get("license", ""))):
			_fail("%s: licencia no permitida '%s'" % [label, entry.get("license", "")])
		if entry.has("path") and not FileAccess.file_exists(str(entry["path"])):
			_fail("%s: el archivo %s no existe" % [label, entry["path"]])
	if ids.is_empty():
		_fail("registro vacío")
	_finish()


func _fail(msg: String) -> void:
	failures += 1
	printerr("FAIL credits: ", msg)


func _finish() -> void:
	print("credits: %d fallas" % failures)
	quit(1 if failures > 0 else 0)
