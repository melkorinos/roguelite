# Ideas & Future Feature Backlog

Consolidated brainstorm space. Items here are **not committed** unless noted otherwise — they're seeds for future design sessions. When an item gets a dedicated session and a decision lands, move it to `memory.md`.

Element/combat reference lives in the in-game Compendium scene, not a separate HTML file.

---

## Elements & Combat

### Damage types and status effects *(T1 implemented 2026-06-03)*
All 12 T1 elements have effects. Gated by `FeatureFlags.status_effects`. See `memory.md` for full spec.
- **Open for future sessions:** Effect display in Compendium and Tooltip (Abilities Panel placeholder).

### Hidden item efficiency function *(internal balance tool)*
Developer-only scoring: `efficiency = w_dps × (eff_dmg / cooldown) + w_effect × effect_value + w_tier × tier_bonus`. Used to detect outliers. Weights are tunable constants, never shown to players.
- Open questions: single score or multi-axis (offence / utility / support)? Target bands per tier (e.g. T1: 3–5, T2: 6–9, T3: 10–14)? Dev Compendium view or CI lint check only?

---

## Ability Chain & Combat

### Innate Ability
One player-owned ability fired once per combat at a chosen moment. The primary player action during combat. Token economy TBD.

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

---

## Progression & Meta

### Meta-progression shape *(dedicated session needed)*
Options: unlock-gated (new Factions/Synergies), cosmetic, XP-based, or hybrid. Do not commit without a session specifically for this — the decision shapes the whole long-term game.

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
