# Handoff — Prototype: Shop → Battle loop

## What this is

A handoff for an agent tasked with updating the existing Phaser 3 scaffold into a minimal playable prototype of the auto-battler. The goal is a runnable loop: **Main Menu → Shop → Battle → Result → back to Shop**.

**Important:** This is a placeholder prototype only. Item and unit design is not final. The primary play-object decision (units vs single character vs items-as-fighters) is explicitly deferred — a further grilling session will happen before the real game-update task. Do not architect around any particular play-object model. Use the word "item" as a neutral placeholder for now.

---

## Read these first

Before touching any code, read the following files in order:

| File | Purpose |
|------|---------|
| [soul.md](soul.md) | Game identity and player fantasy |
| [memory.md](memory.md) | All settled design decisions |
| [goals.md](goals.md) | Sprint 1 checklist — this task covers the prototype items |
| [log.md](log.md) | Development history |
| [../../CONTEXT.md](../../CONTEXT.md) | Domain vocabulary — use these terms in code, comments, and variable names |

---

## Current codebase state

```
src/
  main.ts                 — Phaser game init, registers all scenes
  config/GameConfig.ts    — canvas size, physics settings
  data/types.ts           — GameState, PlayerEntity, ItemEntity, createInitialGameState()
  scenes/
    BootScene.ts          — preloads assets, transitions to MainMenuScene
    MainMenuScene.ts      — Start / Settings / Quit buttons
    SettingsScene.ts      — placeholder settings screen
    GameScene.ts          — OLD: player moves around a room with arrow keys (REPLACE)
    UIScene.ts            — OLD: shows HP overlay (REPLACE)
  systems/
    MovementSystem.ts     — pure function, player movement (KEEP as pattern reference)
    MovementSystem.test.ts — Vitest test (KEEP as test pattern reference)
```

**Architecture rule (hard):** Phaser lives only in `src/scenes/`. Nothing in `src/systems/` or `src/data/` may import Phaser.

**Pattern to follow:** Systems are pure functions — `(state, ...args) => newState`. See `MovementSystem.ts` for the exact shape.

---

## What to build

### 1. Replace `src/data/types.ts`

Replace the existing roguelite types with auto-battler types. Keep the immutable `GameState` pattern.

```typescript
export interface ShopItem {
  id: string;
  label: string;       // 'a' | 'b' | 'c' | 'd' | 'e'
  name: string;
  price: number;
  attack: number;
  defence: number;
}

export interface GameState {
  phase: 'shop' | 'battle' | 'result';
  round: number;
  playerHp: number;
  opponentHp: number;
  gold: number;
  inventory: (ShopItem | null)[];  // always 5 slots
  shopItems: ShopItem[];           // always 5 items
  battleTimer: number;             // seconds elapsed in battle phase
  sandstormFired: boolean;
}

export function createInitialGameState(): GameState { ... }
```

### 2. Add `src/data/itemData.ts`

Five placeholder items. Stats are for prototype purposes only — not final balance.

| Label | Name | Price | Attack | Defence |
|-------|------|-------|--------|---------|
| a | Iron Sword | 10g | +3 | 0 |
| b | Wooden Shield | 8g | 0 | +2 |
| c | Rusty Axe | 14g | +4 | -1 |
| d | Leather Armour | 9g | 0 | +3 |
| e | Lucky Charm | 6g | +1 | +1 |

### 3. Add `src/systems/ShopSystem.ts`

Pure functions. No Phaser imports.

```typescript
buyItem(state: GameState, label: string): GameState
// — checks gold, finds empty inventory slot, deducts cost, places item

sellItem(state: GameState, slotIndex: number): GameState
// — removes item from inventory, refunds half price (floor)

rerollShop(state: GameState): GameState
// — costs 2g, generates a new random set of 5 shop items
```

### 4. Add `src/systems/BattleSystem.ts`

Pure functions. No Phaser imports.

```typescript
// Returns the player's total stats from their inventory
getPlayerStats(inventory: (ShopItem | null)[]): { attack: number; defence: number }

// Tick the battle forward by delta ms. Fires sandstorm at t=10s.
tickBattle(state: GameState, delta: number): GameState
// — increments battleTimer
// — at battleTimer >= 10: sets sandstormFired = true, deals 10 damage to both playerHp and opponentHp
// — transitions phase to 'result' once sandstorm has fired and a beat has passed

// Returns win/loss/draw string
computeResult(state: GameState): 'player_wins' | 'opponent_wins' | 'draw'
```

The opponent for this prototype is a dummy with fixed stats: 20 HP, 2 attack, 1 defence. These values are not meaningful — they exist only to make the result screen work.

### 5. Replace `src/scenes/GameScene.ts` → `src/scenes/ShopScene.ts`

**Layout (800×600 canvas):**

```
┌─────────────────────────────────────────┐
│  Round 1     Gold: 100g     HP: 30/30   │  ← top bar
├─────────────────────────────────────────┤
│  FOR SALE                               │
│  [a] Iron Sword    10g  +3atk           │
│  [b] Wooden Shield  8g  +2def           │
│  [c] Rusty Axe     14g  +4atk -1def     │
│  [d] Leather Armour 9g  +3def           │
│  [e] Lucky Charm    6g  +1atk +1def     │
│                          [Reroll — 2g]  │
├─────────────────────────────────────────┤
│  INVENTORY  (5 slots)                   │
│  [Iron Sword] [empty] [empty] ... [Sell]│
├─────────────────────────────────────────┤
│                          [▶ FIGHT]      │
└─────────────────────────────────────────┘
```

- Clicking a FOR SALE row calls `buyItem` and re-renders.
- Clicking an inventory slot with an item calls `sellItem`.
- Reroll button calls `rerollShop` (costs 2g).
- FIGHT button transitions `phase` to `'battle'` and starts `BattleScene`.

### 6. Replace `src/scenes/UIScene.ts` → `src/scenes/BattleScene.ts`

**Layout:**

```
┌─────────────────────────────────────────┐
│  BATTLE — Round 1                       │
├─────────────────────────────────────────┤
│  YOUR ITEMS            OPPONENT         │
│  Iron Sword (+3atk)    [Dummy Fighter]  │
│  Leather Armour(+3def)                  │
│                                         │
│  YOUR HP: 30           OPP HP: 20       │
│                                         │
│  ⏱ 10s until SANDSTORM...              │
│                                         │
│  [SANDSTORM hits! -10 to both]  ← fires at t=10s
├─────────────────────────────────────────┤
│  Result: YOU WIN / YOU LOSE / DRAW      │
│                    [Next Round] [Menu]  │
└─────────────────────────────────────────┘
```

- Scene calls `tickBattle(state, delta)` each update frame.
- Sandstorm message appears and persists when `state.sandstormFired` becomes true.
- After sandstorm fires, wait ~1 second then show result text and buttons.
- "Next Round" increments `round`, resets HP and battle state, returns to ShopScene.
- "Menu" goes back to MainMenuScene.

### 7. Update `src/scenes/MainMenuScene.ts`

Change the "Start" button to launch `ShopScene` instead of `GameScene + UIScene`:

```typescript
this.scene.start('ShopScene');
```

### 8. Update `src/main.ts`

Register the new scenes and remove old ones:

```typescript
scene: [BootScene, MainMenuScene, SettingsScene, ShopScene, BattleScene]
```

Remove `GameScene` and `UIScene` from the registry (or keep them commented out temporarily).

---

## What to keep unchanged

- `src/scenes/BootScene.ts` — no changes needed
- `src/scenes/SettingsScene.ts` — no changes needed
- `src/config/GameConfig.ts` — no changes needed
- `src/systems/MovementSystem.ts` + its test — keep as reference; do not delete

---

## Tests to add

Add Vitest unit tests for both new systems:

- `src/systems/ShopSystem.test.ts` — test buyItem (sufficient gold, insufficient gold, full inventory), sellItem, rerollShop cost
- `src/systems/BattleSystem.test.ts` — test tickBattle advances timer, sandstorm fires at t=10, computeResult returns correct winner

---

## What is intentionally NOT in scope

- Faction or synergy system
- Merge or Forge mechanics
- Ability Chain combat (real combat is deferred — sandstorm is the placeholder)
- Draft system
- Rarity tiers
- Meta-progression
- Async multiplayer / backend
- Real item balance

---

## Design context summary

A further grilling session will take place before the real game-update task. The following decisions are settled and should be respected even in placeholder code:

- **Genre**: auto-battler, ability-chain combat (The Bazaar-style), async PvP
- **Session**: 20–30 min, Steam desktop target
- **Match**: 8 players, single Player HP bar, proportional damage on loss
- **Upgrade loops**: Merge (3× same → upgrade) + Forge (A+B→C, recipe-based) — not in this prototype
- **Economy**: Gold shop + free Draft each round — only Gold shop in this prototype
- **Factions**: threshold synergies + passive ability interactions — deferred
- **Pieces**: ~30 at launch, Common/Rare/Epic rarity — 5 placeholders in this prototype
- **Play object**: UNDEFINED — do not commit to units, single-character, or items-as-fighters in the architecture
- **Visual identity**: clean, minimal, weird, surreal

Full settled decisions: [memory.md](memory.md)
Full vocabulary: [../../CONTEXT.md](../../CONTEXT.md)

---

## Suggested skills

| Skill | When to use |
|-------|-------------|
| `/tdd` | Building ShopSystem and BattleSystem with tests first |
| `/grill-with-docs` | The follow-up design session (primary play object, ability system, factions) |
| `/prototype` | If any UI layout questions arise — generate variants before committing |
| `/zoom-out` | If unsure how a new system fits the existing architecture |
