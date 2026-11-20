extends RefCounted
## Utilidades de pantalla.


## Márgenes seguros (notch arriba, barra de gestos abajo) en unidades del
## viewport, para no poner nada importante debajo. En escritorio devuelve 0.
static func safe_insets(viewport: Viewport) -> Dictionary:
	var result := {"top": 0.0, "bottom": 0.0}
	if not OS.has_feature("mobile"):
		return result
	var safe := DisplayServer.get_display_safe_area()
	var to_viewport := viewport.get_final_transform().affine_inverse()
	var visible := viewport.get_visible_rect().size
	result.top = maxf(0.0, (to_viewport * Vector2(0.0, safe.position.y)).y)
	result.bottom = maxf(0.0, visible.y - (to_viewport * Vector2(0.0, safe.end.y)).y)
	return result
