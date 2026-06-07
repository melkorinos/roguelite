class_name TuningData

# Single source of truth for the game's **balance knobs** — the values a designer
# tunes for feel. Pure static constants, no SceneTree. Systems reference these
# directly (TuningData.X) rather than holding their own copies.
#
# NOT here (by design — these are correctness/safety/presentation, not balance):
#   BattleSystem.COMBAT_STEP_SECONDS (fixed-step determinism),
#   StatusSystem.MAX_STACKS / AbilitySystem.MAX_REACTIONS_PER_TICK (runaway guards),
#   UIScale / ThemeData (presentation), SettingsManager / AudioManager (infra).
# A later session will gather those into a separate "config constants" file.


# ── Economy ──────────────────────────────────────────────────────────────────
const STARTING_GOLD: int = 20
const GOLD_PER_ROUND: int = 5
const REROLL_BASE_COST: int = 2
const REROLL_COST_STEP: int = 1          # added per paid reroll within a shop phase
const SELL_REFUND_DIVISOR: int = 2       # refund = price / divisor
const SHOP_SLOT_COUNT: int = 5
const INVENTORY_SIZE: int = 6
# Default per-tier element price. Per-element `price` in ElementData may override.
const ELEMENT_PRICE_BY_TIER: Dictionary = { 1: 5, 2: 8, 3: 12, 4: 16 }


# ── Board ────────────────────────────────────────────────────────────────────
const GRID_SIZE: int = 4                  # CombatState.SLOT_COUNT re-exports this


# ── Progression / unlocks ────────────────────────────────────────────────────
const TIER_UNLOCK_THRESHOLDS: Dictionary = { 2: 3, 3: 2, 4: 1 }  # distinct forges to unlock
const STARTING_OPTION_COUNT: int = 3
const STARTING_BUFF_MULTIPLIER: int = 2
# Shop slot 0 is always a T1 (forge fuel). Each of the other four slots independently
# rolls this percent chance to be a higher (unlocked) tier instead of another T1, so
# the mix varies round to round instead of always being 1×T1 + 4×higher.
const SHOP_HIGHER_TIER_SLOT_PERCENT: int = 30


# ── Run / match ──────────────────────────────────────────────────────────────
const STARTING_LIFE: int = 100
const WIN_THRESHOLD: int = 10
const MAX_LIFE_LOSS: int = 30             # lives_lost = round(opp_hp_ratio * MAX_LIFE_LOSS)
const BASE_PLAYER_HP: int = 100
const HP_PER_ROUND: int = 3               # hp = BASE + (round-1)*HP_PER_ROUND + hp_bonus
# Placeholder opponent HP in a fresh GameState, before the first battle replaces it
# with the board-derived value (BattleSystem.compute_opponent_hp in PhaseSystem.to_battle).
const INITIAL_OPPONENT_HP: int = 20


# ── Combat ───────────────────────────────────────────────────────────────────
const BATTLE_TIME_LIMIT: float = 30.0
const OPPONENT_HP_PER_DAMAGE: int = 5
const OPPONENT_HP_MIN: int = 15
const OPPONENT_TIER_ROUND_BREAKS: Array = [2, 4, 6]   # ≤2→T1, ≤4→T2, ≤6→T3, else T4
const OPPONENT_SLOTS_BASE: int = 2
const OPPONENT_SLOTS_ROUND_BREAKS: Array = [1, 3]     # +1 slot past each (≤1→2, ≤3→3, else 4)


# ── Status magnitudes (×1 entries are no-ops today, tunable later) ────────────
const BURN_DAMAGE_PER_STACK: int = 1
const POISON_DAMAGE_PER_STACK: int = 1
const ARMOR_ABSORB_PER_POINT: int = 1            # physical absorb, 1 damage per point
const ARMOR_BURN_ABSORB_DIVISOR: int = 2         # armor soaks burn at half rate
const PLATING_REDUCTION_PER_POINT: int = 1
const WEAKEN_DAMAGE_REDUCTION_PER_STACK: int = 1
const CLEANSE_REMOVE_PER_APPLICATION: int = 1
const HEAL_PER_APPLICATION: int = 1
const LEECH_PER_APPLICATION: int = 1
const BLIND_PERCENT_PER_STACK: int = 15
const BLIND_PERCENT_CAP: int = 50
const SHOCK_SLOW_MAX_PERCENT: float = 50.0       # the 50 in 50n/(n+5)
const SHOCK_SLOW_HALF_STACKS: float = 5.0        # the +5
const HASTE_REDUCTION_DECISECONDS: int = 3
const WEAKEN_DURATION_TICKS: int = 3
const CURSE_DURATION_TICKS: int = 3
const CURSE_DOT_AMPLIFIER: int = 1
const EFFECTIVE_CD_FLOOR_DECISECONDS: int = 10
const DOT_TICK_SECONDS: float = 1.0
