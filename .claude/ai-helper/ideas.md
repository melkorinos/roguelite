# Ideas & Future Feature Backlog

Consolidated brainstorm space. Items here are **not committed** unless noted otherwise — they're seeds for future design sessions. When an item gets a dedicated session and a decision lands, move it to `memory.md`.

For element/combat-specific brainstorm notes (damage types, open-ended forging, efficiency function), also see `.claude/ai-helper/elements-reference.html`.

---

## Elements & Combat

### Damage types and status effects *(planned, design TBD)*
Each element gets a passive effect that fires on hit or cooldown tick. Effect identity should feel native to the element.
- Candidates: Burn 🔥, Poison ☠️, Heal 💚, Slow 🐢, Blind 🌑, Freeze ❄️, Shock ⚡, Shield 🛡️
- Open questions: does an effect replace or layer on top of raw damage? Do T3 results inherit effects from both ingredients? Can the same effect stack from two sources?

### Open-ended forging *(exploring)*
Forge recipes as a discovery mechanic rather than a visible lookup table. Players experiment; the Compendium unlocks as they discover. `discovered_recipes[]` already exists in PlayerProfile as the seam.
- Open questions: hidden entirely vs silhouetted ("???")?  Per-run or persistent across matches? What happens when you forge a pair with no recipe — random output, failure, or junk element? Community shared discovery pool?

### Hidden item efficiency function *(internal balance tool)*
Developer-only scoring: `efficiency = w_dps × (eff_dmg / cooldown) + w_effect × effect_value + w_tier × tier_bonus`. Used to detect outliers. Weights are tunable constants, never shown to players.
- Open questions: single score or multi-axis (offence / utility / support)? Target bands per tier (e.g. T1: 3–5, T2: 6–9, T3: 10–14)? Dev Compendium view or CI lint check only?

### T2 cross-recipe expansion
Lightning ⚡, Nature 🌿, Light ☀️, Dark 🌑, Metal ⚙️, Sound 🔊 currently have **no cross-combo recipes** — only self-combos. These 6 are the most obvious design gap for the next recipe pass.

### T4 / T5 element tiers
Pyramid target (early idea, not committed): 10 / 20 / 30 / 20 / 10 = 90 elements across T1–T5. T4/T5 design fully deferred.

---

## Ability Chain & Combat

### Real Ability Chain combat *(major future milestone)*
Current combat is placeholder damage ticks. Real design: each element fires its Ability in sequence per CONTEXT.md. Interactions between abilities in the chain produce emergent outcomes.

### Innate Ability
One player-owned ability fired once per combat at a chosen moment. The primary player action during combat. Token economy and interaction with chain timing TBD.

### Replay token economy
After a loss, spend a Replay token to re-run combat with Innate fired at a different moment. Finite per-match tokens. Economy design (how many per match, replenishment) TBD.

---

## Build & Shop

### Merge mechanic *(design settled, not yet implemented)*
3× identical piece → upgraded version. Distinct from the current 2-copy Level Up. Deferred; no implementation scope set yet.

### Level 2 Reward *(design settled, not yet implemented)*
Merging to level 2 grants: flat gold payout + player choice of +1 base damage OR −0.5 s cooldown. Full spec in `memory.md`.

### Purchasable Inventory Slots
Buy extra inventory slots with gold during the shop phase. Future strategic layer; not yet scoped.

### Identity pick
"I am playing Water this run" — a run-start declaration that grants bonuses aligned with a chosen element or faction. Bonuses TBD.

### Draft phase *(future)*
Free selection of Items and Trinkets offered each round, separate from the gold shop. Unit/Item/Trinket vocabulary in CONTEXT.md describes the target state; current prototype uses unified Elements.

---

## Board & Synergies

### Grid shape & adjacency
Current prototype is 2×2 (Battlegrid). Adjacency bonuses apply at setup, direction per element, not during combat. Whether the grid grows or stays 2×2 for the final game is TBD.

### Faction system
Category tags on pieces (e.g. Construct, Rogue, Storm). Reaching a threshold count activates a bonus for all pieces of that Faction. Passive ability interactions between specific pieces form emergent Synergies.

---

## Progression & Meta

### Meta-progression shape *(dedicated session needed)*
Options: unlock-gated (new Factions/Synergies), cosmetic, XP-based, or hybrid. Do not commit without a session specifically for this — the decision shapes the whole long-term game.

### Milestones / Internal achievements
In-game achievements that unlock meta-progression content. Infrastructure exists via AchievementSystem + PlayerProfile. First 5 Steam achievements already defined (`ACH_FIRST_WIN` etc.). Reward specifics for internal milestones TBD.

### PvE Rounds & Bosses *(strong option, not committed)*
PvE Rounds on a fixed schedule — all players fight the same encounter. Primary source of Trinkets.
PvE Boss: a damage/defence check milestone; beating it unlocks a Faction, Synergy, or game modifier.

---

## Async PvP & Backend *(future — requires infrastructure)*

### Ghost time-travel aesthetic *(not committed)*
Offer 3 opponent options each round: a Ghost from the previous day's pool, one from the same day, one from the next day. Frames async PvP as time travel — thematically weird and consistent with the game's aesthetic.

### BackendHTTPAdapter for OpponentProvider
Swap the LocalDaySeededAdapter for a real HTTP call that fetches Ghosts from a server. OpponentProvider seam is already in place.

### GodotSteam integration
Custom engine build + real SDK calls for achievements, Cloud Save, and player identity. PlatformLayer autoload (SteamAdapter / NoOpAdapter for web) is identified but not yet built.

### Player accounts + match IDs
Required for storing and serving Ghosts from real sessions. Depends on server infrastructure.

### Opponent board submission
After each match round, submit the player's Composition as a Ghost to the pool for other players to face.
