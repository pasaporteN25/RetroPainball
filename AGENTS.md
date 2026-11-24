# Retro Pinball: guía para agentes

Pinball para Android hecho en **Godot 4.7.2** (GDScript, renderer Compatibility). Textos del juego,
commits y docs en español rioplatense (voseo). Nombres de código, archivos y ramas en inglés.
Este archivo es la única fuente: `CLAUDE.md` solo apunta acá.

## Cómo correr los tests
- Linux: `godot --headless --path . --import` (una vez, o si cambian assets) y después
  `godot --headless --path . -s tests/headless/all.gd` para toda la suite.
- Uno solo: `godot --headless --path . -s tests/headless/<nombre>.gd`.
- Windows: `.\tools\test.ps1`.
- Si un test falla o algo no se probó, decirlo con honestidad.

## Dónde está cada cosa
- `scripts/table/`: piezas y lógica de las mesas (flipper, bumper, bola, reglas y arte por mesa).
- `scripts/ui/`: pantallas y menús.
- `scripts/fx/`: efectos (lámparas, sacudida, celebraciones, ambientes).
- `scripts/autoload/`: singletons (`game_state`, `music`, `settings`, `sfx`).
- `scripts/resources/`: clases de Resource (`TableRules`, `TableTheme`, `RuleStage`).
- `scripts/util/`: utilidades (récords, guardado, estadísticas, navegación).
- `resources/`: datos (`rules/`, `themes/`, `table_physics.tres`, `credits.json`).
- `scenes/`: escenas de mesas, pantallas y `pieces/` (piezas reutilizables).
- `tests/headless/`: la suite. `tools/`: scripts de apoyo (`test.ps1`, capturas, release).
- `docs/`: `PLAN_BETA.md`, `BACKLOG.md`, `ARTE.md`, `mesas/`.

## Estilo
- GDScript tipado (variables, parámetros y retornos con tipo).
- Comentarios de documentación con `##`, en español rioplatense.
- Un test por tema en `tests/headless/<tema>.gd`; entra solo a la suite.
- Todo el dibujo es vectorial y en código, con brillo neón (ver `docs/ARTE.md`).
- Los récords no llevan nombres ni iniciales: el puntaje se guarda solo.

## Ramas y no pisarse
- Una rama por frente (`feature/...`, nunca `codex/`) y un commit por tarea.
- Tests en verde antes de mergear; si cambia algo visible, capturas con `tools/capture_screenshots.gd`.
- No tocar archivos de otro frente en paralelo: lo de la tabla de archivos de `docs/PLAN_BETA.md`
  lo toca solo ese frente mientras esté abierto.
- La rama principal es `master`. No hacer push ni commit si no lo pidieron, ni `--force`.
- Lo marcado como "Decisión de Lucas" en el plan se pregunta antes de implementar.
