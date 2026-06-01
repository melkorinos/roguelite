# Handoff — Godot Port (two phases)

## Phase overview

| Phase | Goal | Status |
|-------|------|--------|
| **Phase 1 — Setup** | Working Godot 4 project: Main Menu + 1 controllable entity in a room | **This handoff** |
| Phase 2 — Prototype | Full loop: Shop → Battle → Result → back to Shop | Next handoff |

---

## Phase 1 — Purpose

Stand up a clean Godot 4 project in the existing repo. By the end of this phase the game must launch, show a main menu, and let the player control a single entity in a room. Nothing more. The auto-battler design (Shop, Battle, systems) is Phase 2.

The existing TypeScript / Phaser codebase (`src/`) is kept as reference and will be deleted once Godot is verified.

---

## All decisions — resolved

| Decision | Answer |
|----------|--------|
| Godot version | **Godot 4.x** (GDScript 2.0) |
| Project location | **`godot/` subdirectory** inside the existing repo, alongside `src/` |
| Existing TypeScript codebase | **Keep as reference** — goal is to delete once Godot port is verified |
| Phase 1 scope | **Main Menu + 1 controllable entity in a room** (not the full prototype) |
| State pattern | **Autoload singleton** (`GameManager.gd`) for global state; pure static methods for system logic |

---

## Confirmed constraints

- **Language**: GDScript (not C#)
- **Canvas**: 800 × 600 px
- **Architecture rule**: Scene scripts (`.gd` attached to `.tscn`) handle rendering and input only. No scene-tree references in system scripts.
- **Vocabulary**: Use terms from [CONTEXT.md](../../CONTEXT.md) in variable names and node names.

---

## Phase 1 — What to build

### Project structure

```
godot/
  project.godot               <- Godot 4 project file (800x600, window mode)
  scenes/
    Boot.tscn                 <- transitions immediately to MainMenu
    Boot.gd
    MainMenu.tscn             <- Start / Settings / Quit
    MainMenu.gd
    Settings.tscn             <- placeholder screen
    Settings.gd
    Game.tscn                 <- room with 1 controllable entity
    Game.gd
  autoloads/
    GameManager.gd            <- global state holder (Autoload)
  data/
    GameState.gd              <- create() factory function
```

### 1. `project.godot`

Create via the Godot editor (File → New Project). Then set:

- Display → Window → Size: 800 × 600
- Display → Window → Stretch → Mode: `canvas_items`
- Application → Run → Main Scene: `res://scenes/Boot.tscn`
- Add Autoload: name `GameManager`, path `res://autoloads/GameManager.gd`

### 2. `data/GameState.gd`

```gdscript
class_name GameState

static func create() -> Dictionary:
    return {
        "phase": "game",
        "player_position": Vector2(400, 300),
        "player_speed": 200.0,
        "player_hp": 30,
    }
```

### 3. `autoloads/GameManager.gd`

```gdscript
extends Node

var state: Dictionary = GameState.create()
```

### 4. `scenes/Boot.tscn` + `Boot.gd`

Scene type: `Node`. One child node, script attached to root.

```gdscript
extends Node

func _ready() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

### 5. `scenes/MainMenu.tscn` + `MainMenu.gd`

Scene type: `Control` (full-rect anchor). Node tree:

```
MainMenu (Control)
  VBoxContainer                <- centred on screen
    Label                      <- game title text
    Button  "Start"
    Button  "Settings"
    Button  "Quit"
```

```gdscript
extends Control

func _on_start_pressed() -> void:
    GameManager.state = GameState.create()
    get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_settings_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
```

Wire each button's `pressed` signal to the corresponding function in the inspector.

### 6. `scenes/Settings.tscn` + `Settings.gd`

Placeholder only. Label ("Settings — coming soon") and a Back button.

```gdscript
extends Control

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
```

### 7. `scenes/Game.tscn` + `Game.gd`

A room with a visible boundary and one player entity (coloured rectangle) moveable with arrow keys / WASD.

Node tree:

```
Game (Node2D)
  ColorRect  "Background"     <- 800x600, dark colour
  ColorRect  "Player"         <- 28x28, bright colour, positioned at (400, 300)
  CanvasLayer "HUD"
    Label    "HpLabel"        <- "HP: 30", top-left
```

```gdscript
extends Node2D

@onready var player: ColorRect = $Player
@onready var hp_label: Label = $HUD/HpLabel

func _ready() -> void:
    player.position = GameManager.state["player_position"]
    hp_label.text = "HP: %d" % GameManager.state["player_hp"]

func _process(delta: float) -> void:
    var direction := Vector2.ZERO
    if Input.is_action_pressed("ui_left"):  direction.x -= 1.0
    if Input.is_action_pressed("ui_right"): direction.x += 1.0
    if Input.is_action_pressed("ui_up"):    direction.y -= 1.0
    if Input.is_action_pressed("ui_down"):  direction.y += 1.0

    var speed: float = GameManager.state["player_speed"]
    player.position += direction.normalized() * speed * delta

    # clamp to room boundary
    player.position.x = clamp(player.position.x, 14.0, 786.0)
    player.position.y = clamp(player.position.y, 14.0, 586.0)

    GameManager.state["player_position"] = player.position
```

---

## Execution order

1. Create `godot/` directory — open Godot 4, create project there
2. Configure project settings (window size, stretch mode, main scene)
3. Write `data/GameState.gd` and `autoloads/GameManager.gd`
4. Register `GameManager` as Autoload in project settings
5. Build `Boot.tscn` → `MainMenu.tscn` → `Settings.tscn` scene chain
6. Build `Game.tscn` with player movement
7. Press F5 — verify: Boot → MainMenu → click Start → player moves in room

**Done when:** F5 launches, main menu shows three buttons, Start drops into a room where the player entity moves with arrow keys.

---

## Mapping: Phaser concept → Godot equivalent

| Phaser / TypeScript | Godot 4 |
|---------------------|---------|
| `Phaser.Scene` class | `.tscn` scene + attached `.gd` script |
| `this.add.text(...)` | `Label` node |
| `this.add.rectangle(...)` | `ColorRect` node |
| Phaser button (text + `setInteractive`) | `Button` node, `pressed` signal |
| `this.scene.start('X')` | `get_tree().change_scene_to_file("res://scenes/X.tscn")` |
| `this.registry` (global data) | `GameManager` Autoload |
| `update(time, delta)` | `_process(delta: float)` |
| `pnpm dev` | Godot editor F5 |

---

## Phase 2 preview (not in scope now)

Phase 2 adds: `ShopSystem.gd`, `BattleSystem.gd`, `ItemData.gd`, `Shop.tscn`, `Battle.tscn`, expanded `GameState` (gold, inventory, phase, round). See [handoff.md](handoff.md) for the full Phase 2 spec — it remains the source of truth for gameplay behaviour once Phase 1 is verified.

---

## Reference files (read before touching code)

| File | Purpose |
|------|---------|
| [soul.md](soul.md) | Game identity |
| [memory.md](memory.md) | Settled design decisions |
| [handoff.md](handoff.md) | Phase 2 spec |
| [../../CONTEXT.md](../../CONTEXT.md) | Domain vocabulary |
