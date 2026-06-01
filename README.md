# Auto-Battler

Early-stage auto-battler built with **Godot 4 / GDScript**. Ability-chain combat, synergy-driven builds, async PvP.

## Run

Open the project in Godot 4 and press **F5**.

```bash
# Command line (if godot is on PATH):
godot --path .
```

## Project structure

```
project.godot          ← Godot 4 project, 1280×720
autoloads/             ← GameManager (global state)
data/                  ← GameState, ItemData
scenes/                ← .tscn + .gd pairs
systems/               ← pure logic (no scene dependencies)
```

## Design docs

`.claude/ai-helper/` contains all design documentation:
- `soul.md` — game identity
- `memory.md` — settled decisions
- `goals.md` — sprint checklist
- `handoff.md` — current implementation task
