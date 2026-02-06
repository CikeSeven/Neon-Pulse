# Repository Guidelines

## Project Structure & Module Organization
This is a Godot 4.x project (`project.godot`) for a lane-based neon shooter.

- `scene/`: gameplay scenes (`world.tscn`, `player.tscn`, `enemy/*.tscn`, `weapon/*.tscn`, `pickup/*.tscn`, `ui/*.tscn`).
- `script/`: GDScript logic mirrored by feature area (`enemy/`, `weapon/`, `pickup/`, `ui/`, plus shared files like `Global.gd`, `Hitbox.gd`, `Hurtbox.gd`).
- `docs/`: design and system docs (`01-游戏总览.md` to `06-UI与数据.md`).
- Root config: `.editorconfig`, `.gitignore`, `.gitattributes`, `project.godot`.

Keep scene/script pairs aligned (example: `scene/enemy/charger.tscn` + `script/enemy/charger.gd`).

## Build, Test, and Development Commands
- `godot4 --path .`: open and run the project in editor mode.
- `godot4 --path . --headless --quit`: quick startup validation for CI/local sanity checks.
- `git log --oneline -n 10`: inspect recent commit style before writing your message.

No dedicated build pipeline or automated test suite is currently configured.

## Coding Style & Naming Conventions
- Encoding: UTF-8 for all files (required).
- Follow existing GDScript style: typed variables where practical, `snake_case` for functions/vars, `PascalCase` for `class_name`.
- Scene/file names use `snake_case` (example: `enemy_spawner.gd`, `laser_bullet.tscn`).
- Keep gameplay constants exported with `@export`/`@export_group` for editor tuning.
- Respect project collision conventions in `project.godot` layers: Player/Enemy, Hitbox/Hurtbox separation.

## Testing Guidelines
Current testing is manual playtesting.

- Verify spawning/movement in `scene/world.tscn`.
- Validate combat interactions: `Hitbox` detects target `Hurtbox` only.
- Check world-scroll behavior: enemies and pickups move left and clean up off-screen.
- For balance changes, include short reproduction steps in PR notes.

## Commit & Pull Request Guidelines
Recent commits use short, imperative Chinese summaries (example: `增加射击敌人`, `抽离敌人受击参数`). Keep messages focused and feature-scoped.

PRs should include:
- What changed and why.
- Affected scenes/scripts (for example `scene/enemy/shooter.tscn`, `script/enemy/shooter.gd`).
- Manual test steps and results.
- Screenshots/GIFs for visible gameplay or UI changes.
