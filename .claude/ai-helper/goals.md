# Goals

## Sprint 0 — Scaffold (COMPLETE — extraction roguelite era, scaffold reused)
- [x] Project setup (Vite + TypeScript + pnpm + Vitest + Phaser 3)
- [x] Folder structure (scenes / systems / data / config)
- [x] Scene chain: Boot → MainMenu → Settings → Game + UI overlay
- [x] Player moves in a room (arrow keys)
- [x] One item placed in the world
- [ ] Item pickup, HUD, first test — DEFERRED (genre pivot to auto-battler)

## Sprint 1 — Core loop: shop → fight (first playable)

Goal: player can open the game, land in a shop, buy pieces, click Fight, watch an Ability Chain resolve, see the result.

- [ ] Redesign `GameState` for auto-battler (Player HP, Gold, piece collection, round number, phase)
- [ ] Piece data model: type, level, Faction, Ability definition, Rarity
- [ ] `MergeSystem`: detect 3 identical pieces → produce upgraded piece
- [ ] `ShopSystem`: generate rotating shop, buy with Gold, reroll (1 Gold)
- [ ] `AbilityChainSystem`: pure TypeScript simulation — run chain, return log of events + final HP delta
- [ ] Vitest tests: MergeSystem, AbilityChainSystem
- [ ] Shop scene (Phaser): display player pieces, shop offers, Gold count, Buy / Sell / Reroll / Fight buttons
- [ ] Combat scene (Phaser): display both Compositions + HP bars, step through Ability Chain events
- [ ] Result screen: show HP change, Replay button (if token available and player lost), Next Round button
- [ ] Wire the loop: Shop → Combat → Result → Shop (round increments)

## Deferred / open
- Primary play object decision (Scenario A / B / C) — resolve before Sprint 1 coding begins
- Draft system (Items/Trinkets)
- Forge system
- Innate Ability + Replay mechanic
- Faction synergy system
- Meta-progression layer
- Backend (async PvP)
- Electron (Steam packaging)
- PvE Bosses (optional)
