# Forge recipe discoverability — reveal all, surface at the bench

## Context

Forge denials were silent ("no recipe" gave no guidance) and recipes were only visible in the Compendium, which was reachable solely from the Main Menu — so mid-run the Forge was opaque. The soul emphasises *discovering* broken combinations, which argues for hiding recipes; but you cannot balance-playtest a loop whose forge is a guessing game.

## Decision

For the first playable slice, **all recipes are revealed** — no discovery gating. Two surfaces make them legible where forging happens:

- **Forge bench hint** — when exactly one element sits in the bench, list every recipe it participates in ("partner → result"), built from a new pure forward lookup `RecipeData.recipes_with(ingredient_id)`. Partners the player owns (inventory + grid, any level) sort first and are highlighted; the list stays level-agnostic but warns when the bench item is below the Level-2 forge minimum (ADR 0008).
- **Compendium reachable from the Shop** — a button opens the existing Compendium and returns to the caller via `GameManager.compendium_return_scene` (default Main Menu).

`FeatureFlags.hidden_recipes` stays the (inert) seam for a future discovery-gated reveal.

## Consequences

Full reveal trades the soul's "discovery mystery" for legibility and playtestability now; discovery-gated reveal is deliberately deferred to a later meta-progression layer (the `hidden_recipes` + `discovered_recipes` machinery already exists for it). When that layer lands, the bench hint and Compendium both filter through the same flag — the surfaces don't change, only which recipes they show.
