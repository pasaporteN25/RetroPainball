# Reglas para agentes (Retro Pinball)

Fuente única para Codex, Claude y cualquier otro agente. `CLAUDE.md` solo apunta acá.
Contexto: [README.md](README.md), [docs/BACKLOG.md](docs/BACKLOG.md) (códigos `G-01`, `S-05`…) y
[docs/PLAN_BETA.md](docs/PLAN_BETA.md) (frentes F0…F8 del pulido de la beta).

## Proyecto

Pinball para Android hecho con **Godot 4.7.2** (GDScript, renderer Compatibility). Textos del juego,
commits y docs en **español rioplatense** (voseo); nombres de código, archivos y ramas en inglés.
El juego es personal: **sin niveles de dificultad** (la complejidad crece de mesa en mesa) y los
récords guardan solo el puntaje, sin iniciales ni nombres.

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Piezas y lógica de las mesas, arte dibujado en código | `scripts/table/` |
| Efectos visuales y de sonido | `scripts/fx/` |
| Menús y pantallas | `scripts/ui/`, `scenes/` |
| Autoloads (`GameState`, `Music`, `Settings`…) | `scripts/autoload/` |
| Definición de los Resources (`TableRules`, `TableTheme`, `TablePhysics`) | `scripts/resources/` |
| Reglas por mesa (datos) | `resources/rules/*.tres` |
| Temas por mesa (paleta, música) | `resources/themes/*.tres` |
| Números de física y sensación | `resources/table_physics.tres` |
| Créditos y licencias de arte, sonido y música | `resources/credits.json` (lo valida un test) |
| Tests headless | `tests/headless/<tema>.gd` |
| Herramientas | `tools/` |

## Tests

- Todos: `godot --headless --path . -s tests/headless/all.gd` (≈6 min; cada test corre en su
  proceso). Solo algunos: agregar `-- solo=nombre1,nombre2`.
- En Windows: `.\tools\test.ps1` (`-Solo nombre`). Godot está en
  `C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe`; en Linux, `godot` del PATH.
- En un worktree nuevo corré antes `godot --headless --path . --import` (genera la caché de
  `class_name`; sin eso todo falla con "Could not find type").
- Un trabajo no está terminado sin los tests en verde, **sin ningún `SCRIPT ERROR`**, y probado en
  la app si cambia algo visible o de juego. Si algo no se pudo probar, decilo.
- Cada test nuevo va en `tests/headless/<tema>.gd` y se corre solo con `all.gd`.

## Estilo

- GDScript **tipado**; comentarios de documentación `##` en español.
- Los números de balance van en Resources (`.tres`), no en el código.
- Cambios de reglas o de física: en los datos antes que en el código.

## Git y trabajo en paralelo

- Rama principal: `master`. Ramas de trabajo con prefijo `feature/` (nunca `codex/`).
- **Una rama por frente y un PR por frente** contra `master`, con `Closes #N` del issue del backlog.
- Dos frentes en paralelo no tocan los mismos archivos (ver la tabla de archivos del frente).
- No hacer push, force-push ni cambiar remotos sin que Lucas lo pida. No renombrar ramas existentes.
- **El que implementa no es el que revisa.**
- Si cambia algo visible, regenerar capturas con `tools/capture_screenshots.gd`.
- Lo marcado como **Decisión de Lucas** en `docs/PLAN_BETA.md` no se resuelve solo: se pregunta.
