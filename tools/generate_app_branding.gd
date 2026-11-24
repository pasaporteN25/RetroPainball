extends SceneTree
## Regenera el ícono, las capas Android y el splash desde el mismo dibujo vectorial.

const ASSET_DIR := "res://assets/branding/"
const STORE_DIR := "res://docs/play/"
const INK := "#071119"
const IVORY := "#f3ead8"
const FLIPPER := "M28 64 C30 60 34 58 39 58 L73 55 C78 55 80 58 79 62 C79 65 77 67 74 68 L42 79 C31 83 23 74 28 64 Z"
const BALL := 'cx="62" cy="39" r="14.5"'
const PALETTE_IDS := ["kernel_panic", "nautilus", "dracula", "alicia"]
const LETTERS := {
	"A": "M0 32 L11 0 L22 32 M4 21 H18",
	"B": "M0 32 V0 H15 L21 5 V11 L16 16 H0 M16 16 L22 21 V27 L16 32 H0",
	"C": "M22 3 L18 0 H6 L0 6 V26 L6 32 H18 L22 29",
	"E": "M21 0 H0 V32 H21 M0 16 H16",
	"I": "M4 0 H18 M11 0 V32 M4 32 H18",
	"L": "M0 0 V32 H22",
	"M": "M0 32 V0 L11 15 L22 0 V32",
	"N": "M0 32 V0 L22 32 V0",
	"O": "M6 0 H16 L22 6 V26 L16 32 H6 L0 26 V6 Z",
	"P": "M0 32 V0 H16 L22 6 V12 L16 18 H0",
	"R": "M0 32 V0 H16 L22 6 V12 L16 18 H0 M12 18 L22 32",
	"T": "M0 0 H22 M11 0 V32",
	"Á": "M0 32 L11 0 L22 32 M4 21 H18 M11 -8 L17 -13",
}


func _initialize() -> void:
	var status := _generate()
	if status != OK:
		printerr("No se pudo generar el arte de arranque: ", error_string(status))
	quit(0 if status == OK else 1)


func _generate() -> Error:
	var status := DirAccess.make_dir_recursive_absolute(ASSET_DIR)
	if status != OK:
		return status
	var accents: Array[String] = []
	for id: String in PALETTE_IDS:
		accents.append("#" + TableTheme.for_table(id).select_accent.to_html(false))
	var accent := accents[0]
	var mark := _mark(accent)
	var full_mark := mark + '<path d="M83 24v8 M79 28h8" fill="none" stroke="%s" stroke-width="1.1" stroke-linecap="round"/>' % accent
	var plate := _plate(accent)
	# Dale margen al dibujo para las máscaras y el movimiento del launcher.
	var adaptive_scale := "translate(5.4 5.4) scale(.9)"
	var silhouette := '<circle %s fill="#fff"/><path fill="#fff" d="%s"/>' % [BALL, FLIPPER]
	var icons := {
		"res://icon.svg": _svg(432, 432, "0 0 108 108", plate[0] + """
<rect x="2" y="2" width="104" height="104" rx="23" fill="url(#plate)" stroke="#29424a" stroke-width="1.3"/>
<rect x="6.5" y="6.5" width="95" height="95" rx="19" fill="none" stroke="#365b5b" stroke-width=".55"/>
""" + plate[1] + _transform(full_mark, "translate(-16.2 -16.2) scale(1.3)")),
		ASSET_DIR + "android_foreground.svg": _svg(432, 432, "0 0 108 108", _transform(mark, adaptive_scale)),
		ASSET_DIR + "android_background.svg": _svg(432, 432, "0 0 108 108",
			plate[0] + '<rect width="108" height="108" fill="url(#plate)"/>' + plate[1]),
		ASSET_DIR + "android_monochrome.svg": _svg(432, 432, "0 0 108 108",
			_transform(silhouette, adaptive_scale)),
	}
	for path: String in icons:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string(icons[path])
		status = file.get_error()
		file.close()
		if status != OK:
			return status
	# El motor lee un PNG antes de que arranque la escena de título.
	var splash := Image.new()
	status = splash.load_svg_from_string(_splash(full_mark, accents))
	if status != OK:
		return status
	status = splash.save_png(ASSET_DIR + "boot_splash.png")
	if status != OK:
		return status
	# Ficha de Play (P-07): ícono de 512 sin esquinas (Play aplica su máscara) y feature graphic.
	# Van a docs/play/, que tiene .gdignore: no se importan ni entran en el AAB.
	var store := {
		STORE_DIR + "icon_512.png": _svg(512, 512, "0 0 108 108", plate[0]
			+ '<rect width="108" height="108" fill="url(#plate)"/>' + plate[1]
			+ _transform(full_mark, "translate(-16.2 -16.2) scale(1.3)")),
		STORE_DIR + "feature_graphic.png": _feature_graphic(full_mark, accents),
	}
	status = DirAccess.make_dir_recursive_absolute(STORE_DIR)
	if status != OK:
		return status
	for path: String in store:
		var image := Image.new()
		status = image.load_svg_from_string(store[path])
		if status != OK:
			return status
		image.convert(Image.FORMAT_RGB8)
		status = image.save_png(path)
		if status != OK:
			return status
	return OK


func _svg(width: int, height: int, view_box: String, body: String) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s">\n<!-- Generado por tools/generate_app_branding.gd -->\n%s\n</svg>\n' % [
		width, height, view_box, body,
	]


func _transform(body: String, transform: String) -> String:
	return '<g transform="%s">%s</g>\n' % [transform, body]


func _plate(accent: String) -> Array[String]:
	return ["""
<defs>
  <radialGradient id="plate" cx=".54" cy=".41" r=".67">
    <stop stop-color="#214a4d"/><stop offset=".56" stop-color="#102932"/><stop offset="1" stop-color="#061019"/>
  </radialGradient>
</defs>
""", """
<g fill="none" stroke="%s" stroke-opacity=".24" stroke-width=".65" stroke-linecap="round">
  <path d="M14 43 V32 Q14 18 28 18 H40 M14 49 V54 M94 66 V76 Q94 90 80 90 H68 M94 59 V55"/>
</g>
""" % accent]


func _mark(accent: String) -> String:
	return """
<defs>
  <radialGradient id="halo" cx=".5" cy=".5" r=".5">
    <stop stop-color="{accent}" stop-opacity=".47"/><stop offset=".55" stop-color="{accent}" stop-opacity=".12"/>
    <stop offset="1" stop-color="{accent}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="steel" cx=".36" cy=".26" r=".84">
    <stop stop-color="#ffffff"/><stop offset=".3" stop-color="#e5eef2"/><stop offset=".54" stop-color="#a7bdcb"/>
    <stop offset=".77" stop-color="#506879"/><stop offset=".91" stop-color="#7697a7"/><stop offset="1" stop-color="#d3eced"/>
  </radialGradient>
  <linearGradient id="flipper" x1=".3" y1="0" x2=".62" y2="1">
    <stop stop-color="{accent}"/><stop offset=".5" stop-color="#29817d"/><stop offset="1" stop-color="#102b39"/>
  </linearGradient>
</defs>
<circle cx="62" cy="39" r="25" fill="url(#halo)"/>
<g fill="none" stroke="{accent}" stroke-linecap="round">
  <path d="M29 51 Q36 43 43 41" stroke-width="4" opacity=".13"/>
  <path d="M29 51 Q36 43 43 41 M32 40 L39 34" stroke-width="1.5" opacity=".75"/>
  <path d="{flipper}" stroke-width="9" opacity=".08"/>
  <path d="{flipper}" stroke-width="5" opacity=".19"/>
</g>
<path d="{flipper}" fill="url(#flipper)" stroke="{accent}" stroke-width="1.85"/>
<path d="M40 61 L73 58.5 Q76 58.5 76 61" fill="none" stroke="#dcfff6" stroke-width="1.25" stroke-linecap="round" opacity=".85"/>
<circle cx="38" cy="69" r="5.6" fill="#132d3a" stroke="{accent}" stroke-width="1.1"/>
<circle cx="38" cy="69" r="1.7" fill="#d4fbf0"/>
<circle {ball} fill="url(#steel)" stroke="#d4e8ed" stroke-width=".8"/>
<path d="M52 37 Q54 30 61 29 M67 49 Q73 46 73.5 42" fill="none" stroke="#f5ffff" stroke-width="1.5" stroke-linecap="round" opacity=".9"/>
""".format({"accent": accent, "flipper": FLIPPER, "ball": BALL})


func _splash(mark: String, accents: Array[String]) -> String:
	var body := '<rect width="720" height="1200" fill="%s"/>' % INK
	body += _transform(mark, "translate(90 223) scale(5)")
	body += _wordmark("RETRO", 681, accents[0])
	body += _wordmark("PINBALL", 807, IVORY)
	for i in accents.size():
		body += '<rect x="%d" y="914" width="70" height="5" rx="2.5" fill="%s"/>' % [
			202 + i * 82, accents[i],
		]
	return _svg(720, 1200, "0 0 720 1200", body)


func _feature_graphic(mark: String, accents: Array[String]) -> String:
	var body := """
<defs>
  <radialGradient id="glow" cx=".3" cy=".5" r=".7">
    <stop stop-color="#16343a"/><stop offset="1" stop-color="%s"/>
  </radialGradient>
</defs>
<rect width="1024" height="500" fill="url(#glow)"/>
""" % INK
	for y in range(0, 500, 10):
		body += '<rect y="%d" width="1024" height="1" fill="%s" fill-opacity=".05"/>' % [y, accents[0]]
	body += _transform(mark, "translate(20 45) scale(3.8)")
	body += _wordmark_at("RETRO", 470, 120, accents[0], 2.2)
	body += _wordmark_at("PINBALL", 470, 225, IVORY, 2.6)
	for i in accents.size():
		body += '<rect x="%d" y="350" width="96" height="7" rx="3.5" fill="%s"/>' % [470 + i * 112, accents[i]]
	return _svg(1024, 500, "0 0 1024 500", body)


func _wordmark(word: String, y: int, tint: String) -> String:
	var width := (word.length() * 29 - 7) * 2.2
	return _wordmark_at(word, (720.0 - width) * 0.5, y, tint, 2.2)


func _wordmark_at(word: String, x: float, y: int, tint: String, scale: float) -> String:
	var lettering := '<g fill="none" stroke="%s" stroke-width="5.5" stroke-linecap="square" stroke-linejoin="bevel">' % tint
	for i in word.length():
		lettering += '<path transform="translate(%d 0)" d="%s"/>' % [i * 29, LETTERS[word[i]]]
	return _transform(lettering + "</g>", "translate(%s %d) scale(%s)" % [x, y, scale])
