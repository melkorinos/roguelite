#!/usr/bin/env python3
"""Render the element-strength table from the balance harness output.

Reads _element_strength.json (written by `godot --headless -s tools/balance_harness.gd`)
plus the live ElementData/AbilityData for names/prices/descriptions, and emits a
dark sortable HTML report: cross-tier power-step matrix + per-tier strength tables
with replacement-delta, contribution breakdown, and outlier flags.
"""
import json, re, pathlib, datetime
from collections import defaultdict

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DATA = ROOT / "data"
TODAY = datetime.date.today().strftime("%Y%m%d")
TODAY_DASH = datetime.date.today().isoformat()
OUT = HERE / f"element-strength-{TODAY}.html"

# noise floor: SE of a mean of n {-1..1} deltas is ~0.45/sqrt(n)
FLAG_PP = 0.12   # |delta| beyond this → strong flag
SOFT_PP = 0.08   # beyond this → soft flag

# ── parse .gd literals (same approach as _build_elements_review.py) ───────────
def strip_literal(text, open_ch, close_ch):
    depth, out, instr = 0, [], False
    for ch in text:
        if ch == '"': instr = not instr
        if not instr:
            if ch == open_ch: depth += 1
            elif ch == close_ch: depth -= 1
        out.append(ch)
        if depth == 0 and out: break
    return "".join(out)

def clean(lit):
    lines = []
    for ln in lit.splitlines():
        instr, cut = False, len(ln)
        for i, ch in enumerate(ln):
            if ch == '"': instr = not instr
            elif ch == '#' and not instr: cut = i; break
        lines.append(ln[:cut])
    return re.sub(r",(\s*[}\]])", r"\1", "\n".join(lines))

def extract(text, marker, op, cl):
    idx = text.index(marker); eq = text.index("=", idx); start = text.index(op, eq)
    return json.loads(clean(strip_literal(text[start:], op, cl)))

el_text = (DATA / "ElementData.gd").read_text(encoding="utf-8")
elements = extract(el_text, "const ELEMENTS:", "[", "]")
damage_dealers = extract(el_text, "const DAMAGE_DEALERS:", "{", "}")
abilities = extract((DATA / "AbilityData.gd").read_text(encoding="utf-8"), "const ABILITIES:", "{", "}")
by_id = {e["id"]: e for e in elements}

run = json.loads((HERE / "_element_strength.json").read_text(encoding="utf-8"))
# Skip ids no longer in the roster (stale JSON) — rerun tools/balance_harness.gd for fresh data.
rows = [r for r in run["elements"] if r["id"] in by_id]
matrix = run["tier_matrix"]

TIER_COLOR = {1:"#38bdf8",2:"#34d399",3:"#a78bfa",4:"#f59e0b"}
CONTRIB_COLOR = {"direct":"#f87171","burn":"#fb923c","poison":"#a3e635","heal":"#4ade80","blocked":"#94a3b8"}

def esc(s): return (s or "").replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")

def pp(x): return f"{x*100:+.1f}"

def contrib_bar(c):
    total = sum(c.values())
    if total <= 0: return '<span class="text-slate-600 text-xs">none</span>'
    cells = []
    for k in ("direct","burn","poison","heal","blocked"):
        v = c.get(k,0)
        if v <= 0: continue
        w = max(2, round(v/total*120))
        cells.append(f'<div title="{k}: {v:.1f} HP/fight" style="width:{w}px;background:{CONTRIB_COLOR[k]}" class="h-3"></div>')
    return f'<div class="flex rounded overflow-hidden">{"".join(cells)}</div><span class="text-xs text-slate-500">{total:.0f} HP</span>'

def flag_for(delta):
    if delta >= FLAG_PP: return ('<span class="pill" style="background:#7f1d1d;color:#fecaca">⚠ overtuned</span>', 2)
    if delta <= -FLAG_PP: return ('<span class="pill" style="background:#1e3a8a;color:#bfdbfe">💤 undertuned</span>', -2)
    if delta >= SOFT_PP: return ('<span class="pill" style="background:#451a03;color:#fdba74">strong</span>', 1)
    if delta <= -SOFT_PP: return ('<span class="pill" style="background:#172554;color:#93c5fd">weak</span>', -1)
    return ('<span class="text-slate-600 text-xs">ok</span>', 0)

# ── per-tier tables ────────────────────────────────────────────────────────────
tier_tables = []
flag_counts = defaultdict(int)
for tier in (1,2,3,4):
    trs = []
    tier_rows = sorted([r for r in rows if r["tier"]==tier], key=lambda r:-r["delta"])
    for r in tier_rows:
        e = by_id[r["id"]]
        ab = abilities.get(r["id"], {})
        delta = r["delta"]
        flag_html, severity = flag_for(delta)
        if severity:  flag_counts[severity] += 1
        color = "#f87171" if delta>=SOFT_PP else ("#60a5fa" if delta<=-SOFT_PP else "#cbd5e1")
        dd = ' <span class="pill" style="background:#78350f;color:#fde68a">DD</span>' if r["id"] in damage_dealers else ""
        trs.append(
            f'<tr><td>{e["emoji"]} {esc(e["name"])}{dd}</td>'
            f'<td class="mono text-right" style="color:{color}">{pp(delta)}</td>'
            f'<td class="mono text-right text-slate-400">{r["win_with"]*100:.0f}%</td>'
            f'<td>{contrib_bar(r["contrib"])}</td>'
            f'<td class="mono text-right text-slate-500">{r["fires"]:.1f}</td>'
            f'<td>{flag_html}</td>'
            f'<td class="text-xs text-slate-400">{esc(ab.get("description",""))}</td></tr>')
    tier_tables.append(
        f'<h3 class="text-lg font-semibold mt-8 mb-2" style="color:{TIER_COLOR[tier]}">Tier {tier} '
        f'<span class="text-slate-500 text-sm font-normal">({len(tier_rows)} elements, sorted strongest→weakest)</span></h3>'
        f'<div class="card p-2"><table class="k text-sm">'
        f'<tr><th>Element</th><th class="text-right" title="mean win-rate change vs a random same-tier replacement, same fights">Δwin (pp)</th>'
        f'<th class="text-right">win%</th><th>HP impact / fight</th><th class="text-right">fires</th><th>verdict</th><th>ability</th></tr>'
        + "".join(trs) + "</table></div>")

# ── cross-tier matrix ──────────────────────────────────────────────────────────
mx_rows = []
for ta in ("1","2","3","4"):
    cells = "".join(
        f'<td class="mono text-center" style="color:{"#4ade80" if matrix[ta][tb]>0.55 else ("#f87171" if matrix[ta][tb]<0.45 else "#cbd5e1")}">{matrix[ta][tb]*100:.0f}%</td>'
        for tb in ("1","2","3","4"))
    mx_rows.append(f'<tr><th style="color:{TIER_COLOR[int(ta)]}">T{ta} board</th>{cells}</tr>')

steps = [matrix["2"]["1"], matrix["3"]["2"], matrix["4"]["3"]]
step_txt = " · ".join(f"T{i+2}-board beats T{i+1}-board {s*100:.0f}%" for i,s in enumerate(steps))

html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Element strength — Monte Carlo replacement value</title>
<script src="https://cdn.tailwindcss.com"></script>
<style>
  body{{background:#0b0e14;color:#cdd6f4;font-family:ui-sans-serif,system-ui,sans-serif}}
  .card{{background:#11151f;border:1px solid #1f2937;border-radius:14px}}
  .mono{{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}}
  .pill{{font-size:11px;padding:2px 8px;border-radius:999px;white-space:nowrap}}
  table.k{{width:100%;border-collapse:collapse}}
  table.k td,table.k th{{padding:5px 9px;border-bottom:1px solid #1f2937;vertical-align:middle}}
  table.k th{{text-align:left;color:#94a3b8;font-weight:600;position:sticky;top:0;background:#11151f}}
</style></head>
<body class="px-6 py-8"><div class="max-w-6xl mx-auto">

<header class="mb-6">
  <h1 class="text-3xl font-bold text-white">Element strength — Monte Carlo replacement value</h1>
  <p class="text-slate-400 mt-1">Generated {TODAY_DASH} · {run["samples_per_element"]} contexts/element × 2 fights · 2×3 mirror boards, tier-pure, Lv1, both sides {run["mirror_hp"]} HP ·
  sim run {run["elapsed_seconds"]:.0f}s · deterministic seeds (reruns reproduce exactly).</p>
  <p class="text-slate-400 mt-1 text-sm"><strong>Δwin</strong> = mean win-rate change vs the SAME fights with this element swapped for a random same-tier element.
  Noise floor ≈ ±6pp at n={run["samples_per_element"]}: <span class="text-slate-300">|Δ| ≥ {FLAG_PP*100:.0f}pp = real outlier (⚠/💤), {SOFT_PP*100:.0f}–{FLAG_PP*100:.0f}pp = watch list, below = fine.</span></p>
</header>

<section class="mb-8">
  <h2 class="text-xl font-bold text-amber-300 mb-2">Tier power-step (cross-tier board win-rates)</h2>
  <div class="card p-4 inline-block">
    <table class="k text-sm"><tr><th></th><th>vs T1</th><th>vs T2</th><th>vs T3</th><th>vs T4</th></tr>
    {"".join(mx_rows)}</table>
    <p class="text-xs text-slate-500 mt-2">{step_txt}. Diagonal ≈ 50% by construction (mirror sanity check).</p>
  </div>
</section>

<section>
  <h2 class="text-xl font-bold text-emerald-300 mb-1">Per-tier strength (replacement value)</h2>
  <p class="text-xs text-slate-500">⚠ {flag_counts[2]} overtuned · {flag_counts[1]} strong · {flag_counts[-1]} weak · 💤 {flag_counts[-2]} undertuned</p>
  {"".join(tier_tables)}
</section>

<footer class="text-xs text-slate-600 border-t border-slate-800 pt-4 mt-8">
  Method: tools/balance_harness.gd (mirror-pool Monte Carlo, replacement deltas, contrib ledgers) → _element_strength.json → this renderer.
  Caveats: Lv1 only · tier-pure boards (no cross-tier synergies) · win% column ≈50% by construction, only Δwin ranks.
</footer>
</div></body></html>"""

OUT.write_text(html, encoding="utf-8")
print("wrote", OUT)
strongest = sorted(rows, key=lambda r:-r["delta"])[:8]
weakest = sorted(rows, key=lambda r:r["delta"])[:8]
print("strongest:", [(r["id"], round(r["delta"],3)) for r in strongest])
print("weakest:", [(r["id"], round(r["delta"],3)) for r in weakest])
print("tier steps:", step_txt)
