class_name FeatureFlags

# Playtest toggles for proposed design features.
# Flip any flag to true to enable that experiment in-game.
# Mirror of the toggle state in .claude/ai-helper/elements-reference.html.
#
# Usage:  if FeatureFlags.status_effects: ...

static var status_effects: bool = false
# Each element carries a passive effect (Burn, Poison, Heal, Slow, Blind, etc.)
# that fires on hit or cooldown tick, layered on top of raw damage.

static var hidden_recipes: bool = false
# Forge recipes are not visible upfront. Players discover them by experimenting.
# Compendium entries unlock on first successful forge.
# (discovered_recipes[] in PlayerProfile is the persistence seam.)

static var efficiency_scoring: bool = false
# Developer-only balance tool. When true, ElementData.effective_damage() also
# prints an efficiency score to the Godot output panel.
# Score = w_dps*(eff_dmg/cooldown) + w_effect*effect_value + w_tier*tier_bonus.

static var ability_chain: bool = false
# Real Ability Chain combat: elements fire Abilities in sequence, interactions
# between them produce emergent outcomes. Replaces the placeholder damage-tick loop.

static var innate_ability: bool = false
# Player fires one Innate Ability per combat at a chosen moment.
# After a loss: spend a Replay token to retrigger with Innate at a different point.
