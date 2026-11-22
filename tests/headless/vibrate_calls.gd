extends SceneTree
## Ningún script debe llamar a Input.vibrate_handheld directo: tiene que pasar por
## Settings.vibrate(...), que respeta la opción de vibración. Única excepción: settings.gd.
## Uso suelto: godot --headless --path . -s tests/headless/vibrate_calls.gd

const ALLOWED := "res://scripts/autoload/settings.gd"
const NEEDLE := "vibrate_handheld"
## Carpetas con código del juego (los tests no cuentan: este mismo archivo menciona el nombre).
const ROOTS: Array[String] = ["res://scripts", "res://tools"]


func _initialize() -> void:
	var offenders: Array[String] = []
	var scanned := 0
	for dir in ROOTS:
		for path in _gd_files(dir):
			scanned += 1
			if path == ALLOWED:
				continue
			var lines := FileAccess.get_file_as_string(path).split("\n")
			for i in lines.size():
				var code := lines[i].split("#")[0]
				if code.contains(NEEDLE):
					offenders.append("%s:%d" % [path, i + 1])
	print("[%s] sin Input.vibrate_handheld fuera de settings.gd (%d scripts revisados)" % ["FAIL" if not offenders.is_empty() else "PASS", scanned])
	for o in offenders:
		print("  FALLÓ: llamada directa en %s (usar Settings.vibrate)" % o)
	var allowed_ok := FileAccess.get_file_as_string(ALLOWED).contains(NEEDLE)
	print("[%s] settings.gd sigue siendo el único punto de vibración" % ["PASS" if allowed_ok else "FAIL"])
	print("\nVibración: %d fallos" % (offenders.size() + (0 if allowed_ok else 1)))
	quit(0 if offenders.is_empty() and allowed_ok else 1)


func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(d)))
	return out
