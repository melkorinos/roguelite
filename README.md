# Auto-Battler

Early-stage auto-battler built with **Godot 4 / GDScript**. Ability-chain combat, synergy-driven builds, async PvP.

## Install & run

1. Download **Godot 4** (standard, not .NET) from [godotengine.org](https://godotengine.org/download)
2. Download or clone this repo
3. Open Godot → **Import** → select `project.godot`
4. Press **F5** to play

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
