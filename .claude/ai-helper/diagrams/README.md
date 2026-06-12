# Diagrams — review artifacts + generators

Working surfaces for element/ability/forge/balance review. HTML outputs are
date-stamped (`-YYYYMMDD`) so regenerating never clobbers an older snapshot.

| File | What | How to (re)generate |
|---|---|---|
| `game-elements-forge-YYYYMMDD.html` | **The element/forge review cockpit**: vis-network forge graph, sortable 105-element roster, recipe in/out-degree tables, damage-dealers, status & trigger glossary, flagged observations (§7). | `python _build_elements_review.py` — instant; parses the live `data/*.gd`, so it is always current. Run after ANY element/recipe/ability data change. |
| `element-strength-YYYYMMDD.html` | **Per-element strength table**: Monte Carlo replacement-value (Δwin vs random same-tier swap), HP-impact breakdown, outlier verdicts, cross-tier power-step matrix. | Two steps: ① `godot --headless -s tools/balance_harness.gd` from **PowerShell** (godot is not on the bash PATH) — ~12–18 min, writes `_element_strength.json`; ② `python _build_element_strength.py`. Rerun ① after any data/balance change — the renderer skips roster-stale ids but the numbers stay stale until the sim reruns. |
| `game-mechanics-20260611.html` | Companion overview of Shop/Battle/damage pipeline/statuses/knobs. Hand-built — **no generator**; treat as a snapshot. | — |
| `_element_strength.json` | Raw harness output (machine state for the renderer). | Written by step ① above. |

Both python scripts parse the GDScript consts directly (strip comments/trailing
commas → `json.loads`), so no Godot is needed for `_build_elements_review.py`.
Methodology details live in the script docstrings and in
`tools/balance_harness.gd`'s header; design decisions in `memory.md`
("Balance tooling") and the 2026-06-12 log entries.
