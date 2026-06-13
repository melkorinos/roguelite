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
const GRID_SIZE: int = 4                  # CombatState.SLOT_COUNT re-exports this; the base board

# Grid Growth (ADR 0014): the player's Battlegrid starts at GRID_BASE_SLOTS and
# grows +1 slot per run when they first OWN an element of a given tier at the given
# level (Merge or Forge result — path-agnostic), each trigger once per run, in
# order, never past GRID_HARD_MAX. Retune freely: reorder, change levels, or add
# entries up to the cap. 9 is intentionally NOT supported.
# Tuned so the slot is a real investment milestone (a T1 Lv2 is too cheap): the
# 5th slot wants a Tier-2 Lv2, the 6th a Tier-3 Lv2.
const GRID_BASE_SLOTS: int = 4
const GRID_HARD_MAX: int = 8
const GRID_GROWTH_TRIGGERS: Array = [
	{ "tier": 2, "level": 2 },  # → 5th slot
	{ "tier": 3, "level": 2 },  # → 6th slot
]


# ── Progression / unlocks ────────────────────────────────────────────────────
const TIER_UNLOCK_THRESHOLDS: Dictionary = { 2: 3, 3: 2, 4: 1 }  # distinct forges to unlock
# Forge gating (ADR 0008): both Forge inputs must be at least this Level — you must
# Merge up before you Forge, coupling the Level and Tier axes and pacing the climb.
# The result comes out PENALTY levels below its inputs (floored at 1), so the
# Merge investment recurs per tier. Set PENALTY to 0 to make it "paid once at the
# base" instead. Forge is gold-free today (cost 0) — the knob is reserved for tuning.
const FORGE_MIN_INPUT_LEVEL: int = 2
const FORGE_RESULT_LEVEL_PENALTY: int = 1
const FORGE_GOLD_COST: int = 0
# Starting Pick / Keystones (ADR 0016): the round-1 choice offers KEYSTONE_OFFER_COUNT
# Keystone Augments and the player hard-commits to one for the whole Run. Per-unit
# magnitudes for the roster (data/KeystoneData.gd) are below — all FLAT integers; scaling
# Keystones multiply these by a board count via scale_by (no percentages — integer combat
# model). Retune freely.
const KEYSTONE_OFFER_COUNT: int = 4
const KEYSTONE_BURN_TICK_BONUS: int = 1
const KEYSTONE_POISON_TICK_BONUS: int = 1
const KEYSTONE_SHOCK_STACK_BONUS: int = 1
const KEYSTONE_ARMOR_FLOOR: int = 2
const KEYSTONE_ARMOR_FLOOR_PER_LEVEL: int = 1            # scaling: per Earth level on board
const KEYSTONE_WEAKEN_DURATION_PER_LEVEL: int = 1        # scaling: per Frost level on board
const KEYSTONE_SHOP_WEIGHT_COPIES: int = 2
const KEYSTONE_BONUS_HP: int = 25
const KEYSTONE_REROLL_DISCOUNT: int = 1
const KEYSTONE_OUTGOING_DAMAGE_PENALTY: int = -2         # Bulwark pact: flat shift per direct hit
const KEYSTONE_COOLDOWN_PENALTY_DECISECONDS: int = 3     # Deepfreeze pact: +0.3s on your own fires
# Shop slot 0 is always a T1 (forge fuel). Each of the other four slots independently
# rolls this percent chance to be a higher (unlocked) tier instead of another T1, so
# the mix varies round to round instead of always being 1×T1 + 4×higher.
const SHOP_HIGHER_TIER_SLOT_PERCENT: int = 30


# ── Run / match ──────────────────────────────────────────────────────────────
const STARTING_LIFE: int = 100
const WIN_THRESHOLD: int = 10
const MAX_LIFE_LOSS: int = 30             # lives_lost = round(opp_hp_ratio * MAX_LIFE_LOSS)
const BASE_PLAYER_HP: int = 130           # G4: lowered so early fights KO in-window (not storm)
const HP_PER_ROUND: int = 11              # hp = BASE + (round-1)*HP_PER_ROUND + hp_bonus; G4: ~matches opponent HP slope (~+11/round)
# Placeholder opponent HP in a fresh GameState, before the first battle replaces it
# with the board-derived value (BattleSystem.compute_opponent_hp in PhaseSystem.to_battle).
const INITIAL_OPPONENT_HP: int = 20


# ── Events (ADR 0011) ─────────────────────────────────────────────────────────
# A non-combat choice node every N rounds: three distinct Event Rewards, pick one.
# First-pass magnitudes — fair game for the G4 balance pass. Persistent rewards
# (bonus HP, reroll discount) accumulate across the Run.
const EVENT_EVERY_N_ROUNDS: int = 3
const EVENT_OFFER_COUNT: int = 3
const EVENT_GOLD_REWARD: int = 15
const EVENT_HP_BONUS_REWARD: int = 30     # → hp_bonus (persistent Run Modifier)
const EVENT_REROLL_DISCOUNT: int = 1      # → reroll_discount (persistent Run Modifier)


# ── Combat ───────────────────────────────────────────────────────────────────
# BATTLE_TIME_LIMIT is the SANDSTORM START, not a hard end (ADR 0012): at this mark
# the Sandstorm begins and combat continues until a side is eliminated.
const BATTLE_TIME_LIMIT: float = 30.0
# Global firing-rate dial (G4): multiplies every element's base cooldown in
# StatusSystem.effective_cooldown_deciseconds. <1 = faster fires (more DPS) WITHOUT
# inflating opponent HP (which keys off `damage`, not cooldown) — the surgical lever for
# making early fights resolve by KO before the Sandstorm. The lone deliberate non-integer
# in the cooldown path: a balance scalar, not a per-element design value; the result is
# still rounded to whole deciseconds and floored.
const COMBAT_COOLDOWN_MULTIPLIER: float = 0.7
# Tier power step (2026-06-12, first rough pass): scales an element's potency —
# status stacks applied per application AND direct hit damage — by its TIER, fixing
# the flat T1→T2 step the balance harness exposed (status potency previously scaled
# with Level only, so a Lv1 T2 hit no harder than a Lv1 T1 at +3g). Values are a
# best-guess 1.5–2.5 band; retune from the next harness run.
# Lv1 potencies land on 1/2/3/4 per tier (1.5/2.5/3.5 round up) — 2.0/2.5 made
# T2 and T3 identical at Lv1, flattening the T2→T3 step (probe: 53%).
const TIER_POTENCY_MULTIPLIER: Dictionary = { 1: 1.0, 2: 1.5, 3: 2.5, 4: 3.5 }
const OPPONENT_BASE_HP: int = 100         # round-1 opponent HP (placeholder; retune in balance)
const OPPONENT_HP_GROWTH_PERCENT: int = 15  # +% of base per round: HP = BASE × (1 + pct·(round-1))
const OPPONENT_HP_MIN: int = 15
const OPPONENT_TIER_ROUND_BREAKS: Array = [2, 4, 6]   # ≤2→T1, ≤4→T2, ≤6→T3, else T4
const OPPONENT_SLOTS_BASE: int = 2
# +1 opponent slot past each break. Extended past 4 so opponents scale with the
# player's Grid Growth (ADR 0014) instead of plateauing at 4 — the 5th/6th breaks
# track the forge climb (T2 Lv2 ≈ r6, T3 Lv2 ≈ r9). Result, capped at GRID_HARD_MAX:
#   ≤1→2, ≤3→3, ≤5→4, ≤8→5, else 6.
const OPPONENT_SLOTS_ROUND_BREAKS: Array = [1, 3, 5, 8]
# Synthetic ghost board generation (G4): make opponent power track the round predictably
# instead of a uniform grab-bag. Most slots field the round's max tier; the rest one tier
# down. Ghost elements also gain Level with the round so opponent offence grows like a
# real board's. Tune these to shape the difficulty curve toward the ~60% win-rate target.
const GHOST_TOP_TIER_FRACTION: float = 0.6            # fraction of slots at the round's max tier
const GHOST_LEVEL_ROUND_BREAKS: Array = [3, 6]        # ghost level: ≤3→Lv1, ≤6→Lv2, else Lv3


# ── Sandstorm (ADR 0012) ──────────────────────────────────────────────────────
# After BATTLE_TIME_LIMIT (the storm START), escalating damage hits BOTH sides each
# second until one is eliminated — so every fight resolves by KO, never a flat
# timeout. Damage of the k-th storm second (k from 0) = BASE + RAMP*k, applied to both
# player_hp and opponent_hp equally.
# DELIBERATE: storm damage is TRUE damage — it bypasses ALL mitigation (armor, plating,
# absorb). The storm is an impartial environmental clock; routing it through defenses
# would let tanky boards outlast it and defeat the purpose. May route through mitigation
# later — this knob block is the reminder that the choice was made on purpose.
const SANDSTORM_BASE_DAMAGE: int = 5             # damage of the first storm second
const SANDSTORM_RAMP_PER_SECOND: int = 5         # added each subsequent storm second
const SANDSTORM_HARD_CAP_SECONDS: float = 60.0   # absolute end — determinism backstop


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
const CURSE_DOT_AMPLIFIER: int = 1        # Curse v2: damage added per consumed charge (per hit / DOT tick)
const EFFECTIVE_CD_FLOOR_DECISECONDS: int = 10
const DOT_TICK_SECONDS: float = 1.0
