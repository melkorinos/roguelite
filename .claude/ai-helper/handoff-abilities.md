# Handoff — Element Special Abilities: Design Session

## Purpose of this session

Decide the **first batch of special abilities** for elements through a grilling session.
No implementation. The output of this session is a finalised list of abilities with agreed names,
triggers, and target elements — ready to hand to an implementation session afterward.

---

## What already exists (don't redesign)

T1 elements already have an **Effect** — a simple status that fires every time the element's
cooldown expires (burn, cleanse, poison, shock, etc.). This is live, tested, and not changing.

The Abilities Panel in the Item Tooltip is a **hard-coded placeholder** — no ability data exists
in the codebase yet. That's the gap.

---

## What the session needs to decide

**1. Vocabulary: what IS an ability, vs what is an effect?**

Effects are already defined (CONTEXT.md): passive, fires on CD expiry, applies a Status.
The new abilities the user has in mind are richer and more varied. The session needs to agree on
what an "ability" means in this game's language before naming any of them.

**2. Trigger taxonomy**

The examples the user gave span several different trigger types. The session needs to settle how
many trigger types exist and what each one is called. Examples given:

| Example | Implied trigger |
|---|---|
| `+1 gold per X cost for this fight` | Post-combat economic reward |
| `Adjacent fire items get +burn` | Board-setup aura |
| `Dispel 50% of current debuffs` | Reactive / on-event |
| `Freeze one random opponent item every X secs` | Periodic active during combat |
| `Disable one random T2 opponent item` | Combat-start targeted debuff |
| `Bonus damage for each fire item on board` | Passive scaling modifier |
| `Decrease cooldown for earth-related elements` | Setup passive modifier |

**3. First batch: which elements, which abilities?**

The grilling session should produce a concrete list. Good starting scope question:
- T1 only? T1 + key T2 archetypes? One ability per tier-cluster?
- Does every element get an ability, or only some?
- Should abilities reinforce element identity (Fire elements buff fire neighbours) or introduce
  new dimensions (Water element that has an economic perk)?

**4. Ability names and descriptions**

Once the triggers and elements are agreed, each ability needs:
- A short canonical name (for data)
- A player-facing description string (for the Abilities Panel display)
- Clear numeric parameters where applicable (every X seconds, +N damage per Y element, etc.)

---

## Constraints the design must respect (but the session does not need to implement)

- The Battlegrid is **2×2** — "adjacent" means sharing an edge on that grid.
- All statuses are **player-side pools**, not per-element — abilities that interact with statuses
  must respect this model.
- T1 elements already have `"effect"` — any new ability field must coexist without collision.
- Economic abilities (+gold) need a hook point that doesn't currently exist — flag this as a
  dependency for the implementation session, not a blocker for design.

---

## Deferred T4 concepts (unrelated to this session, kept for future reference)

Two T4 seed concepts were brainstormed but not implemented:
- **Nebula** — stellar gas / star formation; birth of a star (vs Supernova = death)
- **Void Absolute** — total erasure of light; distinct from Singularity (matter collapse)

---

## Suggested skills

1. **`/grill-with-docs`** — run first, 5 questions at a time. Resolve vocabulary, trigger types,
   scope, and the specific first-batch list.
2. **`/handoff`** at the end — capture the finalised ability list for the implementation session.
