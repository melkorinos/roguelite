#!/usr/bin/env python3
"""Parse the live element/recipe/ability data and emit the element / ability / forge
review HTML (companion to game-mechanics-20260611.html).

The .gd data files are JSON-ish (quoted keys, true/false, trailing commas, # comments)
so we strip comments + trailing commas and json.loads. Then we compute recipe in/out
degree, family lineage, ability summaries, damage-dealer stats, and flagged
observations, and render a self-contained dark HTML with a vis-network forge graph.
"""
import json, re, pathlib, datetime
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[3]
DATA = ROOT / "data"
TODAY = datetime.date.today().strftime("%Y%m%d")
TODAY_DASH = datetime.date.today().isoformat()
OUT = pathlib.Path(__file__).resolve().parent / f"game-elements-forge-{TODAY}.html"

# ── parse the GDScript literals ────────────────────────────────────────────────
def strip_literal(text, open_ch, close_ch):
    depth, out, instr = 0, [], False
    for ch in text:
        if ch == '"':
            instr = not instr
        if not instr:
            if ch == open_ch: depth += 1
            elif ch == close_ch: depth -= 1
        out.append(ch)
        if depth == 0 and out:
            break
    return "".join(out)

def clean(lit):
    lines = []
    for ln in lit.splitlines():
        instr, cut = False, len(ln)
        for i, ch in enumerate(ln):
            if ch == '"': instr = not instr
            elif ch == '#' and not instr:
                cut = i; break
        lines.append(ln[:cut])
    s = "\n".join(lines)
    return re.sub(r",(\s*[}\]])", r"\1", s)

def extract(text, marker, op, cl):
    idx = text.index(marker)
    eq = text.index("=", idx)
    start = text.index(op, eq)
    return json.loads(clean(strip_literal(text[start:], op, cl)))

el_text = (DATA / "ElementData.gd").read_text(encoding="utf-8")
elements = extract(el_text, "const ELEMENTS:", "[", "]")
damage_dealers = extract(el_text, "const DAMAGE_DEALERS:", "{", "}")
recipes = extract((DATA / "RecipeData.gd").read_text(encoding="utf-8"), "const RECIPES:", "[", "]")
abilities = extract((DATA / "AbilityData.gd").read_text(encoding="utf-8"), "const ABILITIES:", "{", "}")

by_id = {e["id"]: e for e in elements}

# ── effect/status presentation (mirror EffectRegistry emojis) ──────────────────
STATUS_EMOJI = {
    "burn":"🔥","poison":"🧪","armor":"🛡️","plating":"🧱","blind":"🙈","shock":"⚡",
    "slow":"🐌","haste":"💨","weaken":"📉","curse":"🌑","leech":"🩸","heal":"💚","cleanse":"🫧",
}
TRIGGER_LABELS = {
    "combat_start":"Combat start","passive":"Passive","passive_on_hit":"On hit",
    "on_burn_applied":"On [burn]","on_heal_applied":"On [heal]","on_leech":"On [leech]",
    "on_poison_tick":"On [poison] tick","on_burn_tick":"On [burn] tick",
    "on_damage_dealt":"On damage dealt","on_armor_stripped":"On armor strip","on_haste_applied":"On [haste]",
}

def trigger_label(ab):
    t = ab.get("trigger","")
    if not t: return ""
    if t == "periodic":
        s = f'{ab.get("interval_deciseconds",0)/10:.1f}'
        if s.endswith(".0"): s = s[:-2]
        lbl = f"Every {s}s"
    elif t == "on_status_applied":
        lbl = f'On [{ab.get("status","")}]'
    elif t == "on_activate":
        n = ab.get("every_n",1)
        lbl = f"Every {n} activations" if n>1 else "On activation"
    else:
        lbl = TRIGGER_LABELS.get(t,t)
    mc = ab.get("multicast",0)
    if mc>0: lbl += f"  ×{mc+1}"
    return lbl

def ability_tags(ab):
    """Set of effect-emoji this ability touches, for the compact 'applies' column."""
    tags = []
    for eff in ab.get("effects",[]):
        st = eff.get("status")
        kind = eff.get("kind","")
        if st and kind in ("apply_status","") :  # apply_status or passive on-hit (no kind)
            tags.append(STATUS_EMOJI.get(st, st))
        elif st and kind == "set_status_field":
            tags.append(STATUS_EMOJI.get(st, st)+"⚙")  # modifies that status's rule
        elif kind == "deal_damage":
            tags.append("💥")
        elif kind == "freeze":
            tags.append("🧊")
        elif kind == "modify_cooldown":
            tags.append("⏱")
        elif kind == "haste_timers":
            tags.append("💨")
        elif kind == "add_max_hp":
            tags.append("❤️")
        elif kind in ("prime_dot", "prime_next_hit"):
            tags.append("🎯")
    if ab.get("aura"):
        tags.append("⚔️")
    out, seen = [], set()
    for t in tags:
        if t not in seen:
            seen.add(t); out.append(t)
    return out

# ── recipe degrees ─────────────────────────────────────────────────────────────
recipes_for = defaultdict(list)      # result -> [(a,b)]
recipes_with = defaultdict(list)     # ingredient -> [(partner,result)]
for r in recipes:
    a,b,res = r["a"],r["b"],r["result"]
    recipes_for[res].append((a,b))
    recipes_with[a].append((b,res))
    if b!=a:
        recipes_with[b].append((a,res))

in_degree = {e["id"]: len(recipes_for.get(e["id"],[])) for e in elements}
out_degree = {e["id"]: len(recipes_with.get(e["id"],[])) for e in elements}
reach = {e["id"]: len({res for _,res in recipes_with.get(e["id"],[])}) for e in elements}

# ── family lineage (dominant T1 root) ──────────────────────────────────────────
T1 = [e["id"] for e in elements if e["tier"]==1]
# tie-break priority: thematic/rare roots win over the original four
PRIORITY = {x:i for i,x in enumerate(
    ["water","fire","air","earth","nature","lightning","light","metal","fungus","dark","frost","blood"])}
FAMILY_NAME = {"water":"Water","fire":"Fire","air":"Air","earth":"Earth","lightning":"Lightning",
    "nature":"Nature","light":"Light","dark":"Dark","metal":"Metal","fungus":"Fungus","blood":"Blood","frost":"Frost"}
FAMILY_COLOR = {"water":"#38bdf8","fire":"#f87171","air":"#5eead4","earth":"#b08968","lightning":"#fbbf24",
    "nature":"#4ade80","light":"#fde68a","dark":"#a78bfa","metal":"#94a3b8","fungus":"#a3e635","blood":"#fb2056","frost":"#7dd3fc"}

_roots_memo = {}
def roots(eid):
    if eid in _roots_memo: return _roots_memo[eid]
    if by_id[eid]["tier"]==1:
        c = Counter({eid:1}); _roots_memo[eid]=c; return c
    c = Counter()
    for a,b in recipes_for.get(eid,[]):
        c += roots(a); c += roots(b)
    if not c:  # safety (shouldn't happen)
        c = Counter({eid:1})
    _roots_memo[eid]=c; return c

def family_of(eid):
    c = roots(eid)
    return max(c.items(), key=lambda kv:(kv[1], PRIORITY.get(kv[0],-1)))[0]

family = {e["id"]: family_of(e["id"]) for e in elements}

TIER_COLOR = {1:"#38bdf8",2:"#34d399",3:"#a78bfa",4:"#f59e0b"}
TIER_NAME = {1:"T1",2:"T2",3:"T3",4:"T4"}

# ── per-element enriched record ────────────────────────────────────────────────
records = []
for e in elements:
    eid = e["id"]
    ab = abilities.get(eid, {})
    is_t1 = e["tier"]==1
    eff_field = e.get("effect")
    if is_t1 and eff_field:
        tl = "On fire"
        tags = [STATUS_EMOJI.get(eff_field, eff_field)]
        desc = ab.get("description","")
    else:
        tl = trigger_label(ab)
        tags = ability_tags(ab)
        desc = ab.get("description","")
    dd = eid in damage_dealers
    TIER_MULT = {1:1.0, 2:1.5, 3:2.5, 4:3.5}  # TuningData.TIER_POTENCY_MULTIPLIER
    eff1 = max(1, round(e.get("damage",0) * TIER_MULT[e["tier"]])) if dd else 0
    records.append({
        "id":eid,"name":e["name"],"emoji":e["emoji"],"tier":e["tier"],"price":e["price"],
        "cd":e["cooldown_deciseconds"],"cds":round(e["cooldown_deciseconds"]/10,1),
        "damage":e.get("damage",0),"dd":dd,"eff1":eff1,
        "family":family[eid],"famName":FAMILY_NAME[family[eid]],
        "inDeg":in_degree[eid],"outDeg":out_degree[eid],"reach":reach[eid],
        "trigger":tl,"desc":desc,"applies":tags,"hasAbility":bool(ab) and not is_t1,
    })
rec_by_id = {r["id"]: r for r in records}

# ── graph nodes/edges ──────────────────────────────────────────────────────────
nodes = []
for r in records:
    deg = r["inDeg"] + r["outDeg"]
    nodes.append({
        "id":r["id"], "label":f'{r["emoji"]} {r["name"]}',
        "tier":r["tier"], "family":r["family"],
        "tierColor":TIER_COLOR[r["tier"]], "famColor":FAMILY_COLOR[r["family"]],
        "value": deg, "inDeg":r["inDeg"], "outDeg":r["outDeg"], "dd":r["dd"],
        "title": f'{r["emoji"]} {r["name"]} · {TIER_NAME[r["tier"]]} · {r["famName"]} family\n'
                 f'made by {r["inDeg"]} recipe(s) · feeds {r["outDeg"]} recipe(s) → {r["reach"]} distinct results'
                 + ("\n★ damage-dealer" if r["dd"] else ""),
    })
edges = []
for r in recipes:
    edges.append({"from":r["a"],"to":r["result"]})
    if r["b"]!=r["a"]:
        edges.append({"from":r["b"],"to":r["result"]})

# ── observations (computed) ────────────────────────────────────────────────────
def names(ids): return ", ".join(f'{by_id[i]["emoji"]} {by_id[i]["name"]}' for i in ids)

# single-path (in-degree 1) results, T3/T4
single_t3 = sorted([r["id"] for r in records if r["tier"]==3 and r["inDeg"]==1])
single_t4 = sorted([r["id"] for r in records if r["tier"]==4 and r["inDeg"]==1])
# over-converged (in-degree >=4)
overconv = sorted([r for r in records if r["inDeg"]>=4], key=lambda r:-r["inDeg"])
# heavily-used non-T1 ingredients (out-degree)
heavy_used = sorted([r for r in records if r["tier"]>=2], key=lambda r:-r["outDeg"])[:12]
# empty-effect abilities — exempt aura carriers (the aura field IS the ability)
# and bare-multicast damage-dealers (the doubled hit IS the ability, e.g. carnage)
empty_eff = sorted([eid for eid,ab in abilities.items()
                    if ab.get("trigger") and ab.get("effects",None)==[]
                    and not ab.get("aura")
                    and not (ab.get("multicast",0)>0 and eid in damage_dealers)])
# duplicate ability signatures
def sig(ab):
    effs = sorted(json.dumps(e, sort_keys=True) for e in ab.get("effects",[]))
    return json.dumps({"t":ab.get("trigger"),"i":ab.get("interval_deciseconds"),
        "m":ab.get("multicast"),"s":ab.get("status"),"n":ab.get("every_n"),
        "c":ab.get("chance"),"a":ab.get("aura"),"e":effs}, sort_keys=True)
sig_groups = defaultdict(list)
for eid,ab in abilities.items():
    if by_id.get(eid,{}).get("tier",1)==1: continue
    if not ab.get("trigger"): continue
    sig_groups[sig(ab)].append(eid)
dupe_groups = sorted([sorted(v) for v in sig_groups.values() if len(v)>1], key=lambda g:-len(g))
# damage-dealer distribution by family + families with none
dd_by_family = defaultdict(list)
for r in records:
    if r["dd"]: dd_by_family[r["family"]].append(r["id"])
fams_no_dd = [FAMILY_NAME[f] for f in FAMILY_NAME if f not in dd_by_family]
# T4 ability stubs
t4_stub = sorted([r["id"] for r in records if r["tier"]==4 and not r["hasAbility"]])
# cooldown outliers (slowest)
slow_cd = sorted(records, key=lambda r:-r["cd"])[:8]

# tier counts / ability coverage / status coverage
tier_counts = Counter(r["tier"] for r in records)
fam_counts = Counter(r["famName"] for r in records)
trigger_counts = Counter()
for eid,ab in abilities.items():
    if by_id.get(eid,{}).get("tier",1)==1: continue
    t = ab.get("trigger")
    if t: trigger_counts[trigger_label(ab).split("  ×")[0]] += 1
status_usage = Counter()
for eid,ab in abilities.items():
    if by_id.get(eid,{}).get("tier",1)==1:
        ef = by_id[eid].get("effect")
        if ef: status_usage[ef]+=1
        continue
    seen=set()
    for eff in ab.get("effects",[]):
        st = eff.get("status")
        if st and st not in seen:
            seen.add(st); status_usage[st]+=1

# ── status mechanics glossary (from StatusSystem.gd behaviour) ─────────────────
STATUS_MECHANICS = [
    ("🔥","Burn","DOT","stacks × 1 dmg / tick (+bonus)","Ramping DOT. −1 stack each 1s tick. Armor absorbs it at HALF rate (raw/2), never below armor floor. Steel's plating can also shave it. A DOT tick is a 'damaging event' → consumes a curse charge."),
    ("🧪","Poison","DOT","stacks × 1 dmg / tick (+bonus)","Permanent DOT — stacks NEVER decrement. Armor does NOT soak poison at all (only plating-reduces_dot can). Underrot adds +1/tick. The slow-burn win condition."),
    ("🛡️","Armor","Mitigation","absorbs 1 dmg / point","Depletes as it soaks direct hits + half of burn; never below its floor (Mountain floors it at 2). Acid (WIRED): once stripped to 0, armor cannot regenerate for the combat. Strip-to-0 emits on_armor_stripped."),
    ("🧱","Plating","Mitigation","−1 dmg / point, flat","Flat reduction on EVERY direct hit; never depletes. Only touches DOT when reduces_dot is set (Steel). The anti-chip-damage wall."),
    ("🙈","Blind","Miss","+15% / stack, cap 50%","Per-fire miss roll from the seeded RNG. A blinded element may fire and do nothing. Caps at 50% so it can't lock a board."),
    ("⚡","Shock","Slow","50·n/(n+5) % slower CD","Cooldown tax with diminishing returns (1→8%, 3→19%, 10→33%). Plasma treats n as +3; Tempest (WIRED) makes it cleanse-proof. Pure tempo denial."),
    ("💨","Haste","Speed","−0.3s / stack","Side-wide cooldown reduction. Gust upgrades it to −0.5s. The only self-speed status."),
    ("📉","Weaken","Debuff","−1 dmg / stack, 3 ticks","Reduces the WEAKENED element's direct hits only (lives on the attacker). Timed — expires after 3 ticks (Blackice +2). Does NOT touch DOT."),
    ("🌑","Curse","Amplify","+1 dmg / charge consumed","v2: each damaging event (a hit OR a DOT tick > 0) consumes one charge and adds the amplifier. No duration — runs out of charges. Void/Voidrift apply a deep 10-charge curse; Shade/Umbra/Eclipse raise the amplifier."),
    ("🩸","Leech","Lifesteal","heal = damage dealt","Instant self-heal equal to damage dealt on fire. Pulse adds +1; Ichor doubles it. Only meaningful on elements that actually deal damage."),
    ("💚","Heal","Sustain","+1 HP / application","Instant side heal. Fuels on_heal_applied reactors (Ember, Lifebloom, Bloomspark, Photosynthesis)."),
    ("🫧","Cleanse","Removal","remove 1 stack / application","Strips 1 stack each from burn/poison/shock/slow/weaken/blind on your side. The only debuff answer."),
    ("🧊","Freeze","Lockout","pause an element N seconds","Not a StatusSystem status — own per-side timer. Frozen slot can't fire and its cooldown stalls. Anti-permalock target selection. Permafrost 5s, Freeze 8s, Glacier 2×5s, Ice Age 2×8s."),
    ("🎯","Primers","One-shot buff","+N on the NEXT tick / hit","NEW (2026-06-12). prime_dot: the target's next burn/poison tick deals +N, then resets (waits until that DOT actually ticks — Blight, Molten). prime_next_hit: your side's next damaging direct hit deals +N (Crystal, Aether)."),
    ("❤️","Max HP","Per-fight bulk","+N HP and bar max","NEW (2026-06-12). add_max_hp raises the side's HP AND its bar max for this fight only. Level-scaled. Ironwood +6, Ancient Grove +10, World Tree +1 per activation (it keeps growing)."),
    ("⚔️","Aura","Adjacency buff","adjacent hits +N","NEW (2026-06-12). A passive aura: adjacent damage-dealers hit +N harder (level-scaled; pure-effect neighbors stay at 0 per ADR 0013). Root +1, Obsidian +2, Primordial +3. Placement now matters."),
]

# ════════════════════════════════════════════════════════════════════════════════
# HTML
# ════════════════════════════════════════════════════════════════════════════════
def esc(s): return (s or "").replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")

def bar_rows(counter, color, fmt=lambda k:k, total=None):
    mx = max(counter.values()) if counter else 1
    rows=[]
    for k,v in counter.most_common():
        w = int(v/mx*100)
        rows.append(f'<div class="flex items-center gap-2 text-xs my-0.5"><div class="w-40 text-slate-300 truncate">{esc(fmt(k))}</div>'
                    f'<div class="flex-1 bg-slate-800 rounded h-3"><div style="width:{w}%;background:{color}" class="h-3 rounded"></div></div>'
                    f'<div class="w-8 text-right text-slate-400 mono">{v}</div></div>')
    return "".join(rows)

# roster rows
def applies_html(tags): return " ".join(f'<span>{t}</span>' for t in tags)
roster_rows = []
for r in sorted(records, key=lambda r:(r["tier"], -r["inDeg"], r["name"])):
    dd_badge = '<span class="pill bg-amber-900 text-amber-200">DD</span>' if r["dd"] else ''
    roster_rows.append(
        f'<tr class="row" data-tier="{r["tier"]}" data-dd="{int(r["dd"])}" data-ab="{int(r["hasAbility"])}" '
        f'data-name="{esc(r["name"].lower())} {r["id"]}">'
        f'<td>{r["emoji"]} {esc(r["name"])} {dd_badge}</td>'
        f'<td class="mono" style="color:{TIER_COLOR[r["tier"]]}">{TIER_NAME[r["tier"]]}</td>'
        f'<td><span style="color:{FAMILY_COLOR[r["family"]]}">{esc(r["famName"])}</span></td>'
        f'<td class="mono text-center" data-sort="{r["inDeg"]}">{r["inDeg"]}</td>'
        f'<td class="mono text-center" data-sort="{r["outDeg"]}">{r["outDeg"]}</td>'
        f'<td class="mono text-center">{r["cds"]}s</td>'
        f'<td class="mono text-center" data-sort="{r["eff1"]}">{r["eff1"] if r["dd"] else "·"}</td>'
        f'<td class="text-slate-400">{esc(r["trigger"])}</td>'
        f'<td>{applies_html(r["applies"])}</td>'
        f'<td class="text-slate-300 text-xs">{esc(r["desc"])}</td>'
        f'</tr>')

# damage-dealer table
dd_rows=[]
for r in sorted([x for x in records if x["dd"]], key=lambda r:(r["tier"], -r["eff1"])):
    dd_rows.append(f'<tr><td>{r["emoji"]} {esc(r["name"])}</td>'
        f'<td class="mono" style="color:{TIER_COLOR[r["tier"]]}">{TIER_NAME[r["tier"]]}</td>'
        f'<td><span style="color:{FAMILY_COLOR[r["family"]]}">{esc(r["famName"])}</span></td>'
        f'<td class="mono text-center">{r["damage"]}</td>'
        f'<td class="mono text-center">{r["eff1"]}</td>'
        f'<td class="mono text-center">{max(1, round(r["damage"]*2 * {1:1.0,2:1.5,3:2.5,4:3.5}[r["tier"]]))}</td>'
        f'<td class="mono text-center">{max(1, round(r["damage"]*3 * {1:1.0,2:1.5,3:2.5,4:3.5}[r["tier"]]))}</td>'
        f'<td class="mono text-center">{r["cds"]}s</td>'
        f'<td class="text-slate-300 text-xs">{esc(r["trigger"])} — {esc(r["desc"]) if r["desc"] else "no ability (pure hit)"}</td></tr>')

# convergence table (results by in-degree)
conv_rows=[]
for r in sorted([x for x in records if x["tier"]>=2], key=lambda r:(-r["inDeg"], r["tier"], r["name"])):
    paths = recipes_for.get(r["id"],[])
    paths_str = "; ".join(f'{by_id[a]["emoji"]}+{by_id[b]["emoji"]}' for a,b in paths)
    cls = "text-rose-300" if r["inDeg"]>=4 else ("text-amber-200" if r["inDeg"]==1 else "text-slate-300")
    conv_rows.append(f'<tr><td>{r["emoji"]} {esc(r["name"])}</td>'
        f'<td class="mono" style="color:{TIER_COLOR[r["tier"]]}">{TIER_NAME[r["tier"]]}</td>'
        f'<td class="mono text-center {cls}">{r["inDeg"]}</td>'
        f'<td class="text-xs text-slate-400">{paths_str}</td></tr>')

# reach table (ingredients by out-degree, T2+)
reach_rows=[]
for r in heavy_used:
    feeds = recipes_with.get(r["id"],[])
    feeds_str = "; ".join(sorted({f'{by_id[res]["emoji"]} {by_id[res]["name"]}' for _,res in feeds}))
    reach_rows.append(f'<tr><td>{r["emoji"]} {esc(r["name"])}</td>'
        f'<td class="mono" style="color:{TIER_COLOR[r["tier"]]}">{TIER_NAME[r["tier"]]}</td>'
        f'<td class="mono text-center text-emerald-300">{r["outDeg"]}</td>'
        f'<td class="mono text-center">{r["reach"]}</td>'
        f'<td class="text-xs text-slate-400">{feeds_str}</td></tr>')

# status glossary rows
gloss_rows=[]
for emoji,name,kind,mag,beh in STATUS_MECHANICS:
    gloss_rows.append(f'<tr><td class="whitespace-nowrap">{emoji} <strong>{name}</strong></td>'
        f'<td><span class="pill bg-slate-700 text-slate-200">{kind}</span></td>'
        f'<td class="mono text-xs text-amber-200">{esc(mag)}</td>'
        f'<td class="text-sm text-slate-300">{esc(beh)}</td></tr>')

# observations html
def obs_card(title, body, tone="note"):
    return f'<div class="card p-4 {tone} formula"><p class="font-semibold mb-1">{title}</p>{body}</div>'

dupe_html = "".join(f'<li><span class="mono text-amber-200">{esc(trigger_label(abilities[g[0]]))}</span> — '
    f'{names(g)} <span class="text-slate-500">(identical ability)</span></li>' for g in dupe_groups)
dd_fam_html = "".join(f'<li><span style="color:{FAMILY_COLOR[f]}">{FAMILY_NAME[f]}</span>: {names(ids)}</li>'
    for f,ids in sorted(dd_by_family.items(), key=lambda kv:-len(kv[1])))

# out-degree spread for the rebalance-status card
out_dist = Counter(r["outDeg"] for r in records if r["tier"] in (2,3))
out_dist_str = ", ".join(f'{d} path{"s" if d!=1 else ""}: {n}' for d,n in sorted(out_dist.items()))
ramp_cd = sorted([eid for eid,ab in abilities.items() if any(
    (e.get("kind")=="modify_cooldown") for e in ab.get("effects",[])) and ab.get("trigger") in ("on_activate","on_status_applied")])

OBS = []
OBS.append(obs_card("✅ FIXED 2026-06-12 — forge-path spread (your concern #2)",
    f'<p class="text-sm text-slate-300">Every T2/T3 now feeds <strong>≥2 recipes</strong> (was: 65 elements at exactly 1), capped at 6 '
    f'(was: Rain 10, four elements at 7). Spread today: <span class="mono">{esc(out_dist_str)}</span>. T1 stays at 12 each — they are the roots, by design. '
    f'Done via 14 thematic ingredient swaps + 31 new recipes pairing previously single-use elements (191 → {len(recipes)}).</p>'
    f'<p class="text-xs text-amber-200 mt-2">Cost to push back on: T3/T4 in-degree drifted up — most results now have 4 paths (band 2–5; meteorite + tectonic at 5, both structurally forced as sole metal/earth sinks). '
    f'The out-degree floor and the in-degree compression pull against each other; this is the chosen trade.</p>', "note"))
OBS.append(obs_card("✅ FIXED 2026-06-12 — trigger mix + dead abilities",
    f'<p class="text-sm text-slate-300">combat_start 37 → {trigger_counts.get("Combat start",0)} (true setup only) · '
    f'"Every Xs" periodic 31 → 3 iconic engines (lava, volcano, rainbow) · on_activate is the new workhorse (rides the element\'s own cooldown). '
    f'New vocabulary: 🎯 primers (next-tick / next-hit), ❤️ max-HP-for-the-fight, ⚔️ adjacency auras, build-up payoffs (every_n 3–4), ×3 multicast at T4. '
    f'All 7 duplicate-ability pairs differentiated; Voltspore/Acid/Tempest wired for real; all 10 T4 Phenomena designed.</p>'
    + (f'<p class="text-xs text-rose-300 mt-2">Still empty-effect (regression check): {names(empty_eff)}</p>' if empty_eff else
       '<p class="text-xs text-slate-500 mt-2">Zero dead abilities remain (Carnage\'s bare ×2 multicast is real damage — it is a damage-dealer).</p>'), "note"))
if dupe_groups:
    OBS.append(obs_card("🔁 Duplicate abilities (regression check)",
        f'<ul class="text-sm text-slate-300 list-disc ml-5 space-y-1">{dupe_html}</ul>', "warn"))
OBS.append(obs_card("⚖️ Haste & blind redistribution — strength still unreviewed",
    f'<p class="text-sm text-slate-300">Blind appliers trimmed 22 → {status_usage.get("blind",0)}; haste appliers raised 3 → {status_usage.get("haste",0)} '
    f'(air, beacon, cloud, storm, rainbow, aether + Gust\'s upgrade + Aurora\'s reactor). '
    f'<strong>Open question for the step-⑥ status review:</strong> haste is a permanent, stacking, side-wide −0.3s; with more appliers it may now be the strongest buff in the game. '
    f'Counterplay exists (shock, freeze, cooldown penalties) but the magnitude knob (HASTE_REDUCTION_DECISECONDS) has never been balance-passed.</p>', "warn"))
OBS.append(obs_card("⏱ New ramping cooldown-modifier abilities — watch the floor",
    f'<p class="text-sm text-slate-300">{names(ramp_cd)} now ramp the side-wide cooldown modifier every activation/event. '
    f'Penalties stack without cap (slowing ramps are bounded only by combat length) and reductions race to the 1s floor. '
    f'Deliberate tempo identity — but simulate matchups stacking two of them before trusting the numbers.</p>', "warn"))
OBS.append(obs_card("💥 Damage-dealers cluster in a few families",
    f'<p class="text-sm text-slate-300">Only {sum(len(v) for v in dd_by_family.values())} of 132 elements deal direct damage. By family:</p>'
    f'<ul class="text-xs text-slate-300 list-disc ml-5 mt-1 space-y-0.5">{dd_fam_html}</ul>'
    f'<p class="text-xs text-amber-200 mt-2">Families with NO damage-dealer at all: {esc(", ".join(fams_no_dd))} — intended by ADR 0013, but the new ⚔️ auras only help damage-dealers, so aura value is uneven across families.</p>', "note"))
OBS.append(obs_card("🌀 Naming collision + leftover flags",
    f'<p class="text-sm text-slate-300"><strong>Sandstorm the element</strong> (T3 🌀) vs <strong>Sandstorm the sudden-death storm</strong> (ADR 0012) collide in UI copy — rename one before players meet both. '
    f'15 Group-G placeholder T2 names still pending. Slowest firers: '
    + ", ".join(f'{r["emoji"]} {esc(r["name"])} ({r["cds"]}s)' for r in slow_cd[:5])
    + f' — with build-up every_n gates on top (Tsunami every 4th ≈ 17s between crashes), check payoffs land before the storm (t=30s).</p>', "warn"))

NODES_JSON = json.dumps(nodes)
EDGES_JSON = json.dumps(edges)
FAM_LEGEND = "".join(f'<span class="pill" style="background:{c}22;color:{c};border:1px solid {c}55">{FAMILY_NAME[f]}</span>' for f,c in FAMILY_COLOR.items())

html = """<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Auto-Battler — Elements · Abilities · Forge review</title>
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
<style>
  body{background:#0b0e14;color:#cdd6f4;font-family:ui-sans-serif,system-ui,sans-serif}
  .card{background:#11151f;border:1px solid #1f2937;border-radius:14px}
  .mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  .pill{font-size:11px;padding:2px 8px;border-radius:999px}
  h2{scroll-margin-top:70px}h3{scroll-margin-top:70px}
  table.k{width:100%;border-collapse:collapse}
  table.k td,table.k th{padding:5px 9px;border-bottom:1px solid #1f2937;vertical-align:top}
  table.k th{text-align:left;color:#94a3b8;font-weight:600;cursor:pointer;position:sticky;top:0;background:#11151f}
  table.k th.sortable:hover{color:#e2e8f0}
  code{background:#1e2535;padding:1px 5px;border-radius:5px;color:#fde68a}
  .formula{border-left:3px solid #f59e0b;padding:10px 14px;border-radius:6px}
  .warn{background:#2a1414;border-left-color:#ef4444}
  .note{background:#0f2018;border-left-color:#22c55e}
  #graph{height:680px;background:#0e1320;border-radius:12px;border:1px solid #1f2937}
  .ctrlbtn{font-size:12px;padding:4px 10px;border-radius:8px;background:#1e2535;color:#cdd6f4;border:1px solid #334155;cursor:pointer}
  .ctrlbtn.on{background:#334155;color:#fff;border-color:#64748b}
  input,select{background:#0e1320;border:1px solid #334155;border-radius:8px;color:#e2e8f0;padding:4px 8px;font-size:13px}
</style></head>
<body class="px-6 py-8"><div class="max-w-7xl mx-auto">

<header class="mb-8">
  <h1 class="text-3xl font-bold text-white">Elements · Abilities · Forge — review surface</h1>
  <p class="text-slate-400 mt-1">Generated from live data (<span class="mono">data/ElementData · RecipeData · AbilityData · EffectRegistry · StatusSystem</span>) on 2026-06-11. Companion to <span class="mono">game-mechanics-20260611.html</span>. <strong>__NEL__ elements · __NRE__ recipes · __NAB__ abilities · __NDD__ damage-dealers.</strong></p>
  <nav class="flex flex-wrap gap-2 mt-4 text-sm">
    <a class="pill bg-sky-900 text-sky-200" href="#overview">① Overview</a>
    <a class="pill bg-indigo-900 text-indigo-200" href="#graph-sec">② Forge network</a>
    <a class="pill bg-rose-900 text-rose-200" href="#imbalance">③ Recipe imbalance</a>
    <a class="pill bg-emerald-900 text-emerald-200" href="#roster">④ Element roster</a>
    <a class="pill bg-amber-900 text-amber-200" href="#dd">⑤ Damage-dealers</a>
    <a class="pill bg-violet-900 text-violet-200" href="#mech">⑥ Status & ability mechanics</a>
    <a class="pill bg-slate-700 text-slate-200" href="#obs">⑦ Flagged observations</a>
  </nav>
</header>

<!-- OVERVIEW -->
<section id="overview" class="mb-12">
  <h2 class="text-2xl font-bold text-sky-300 border-b border-sky-900 pb-2 mb-4">① Overview</h2>
  <div class="grid md:grid-cols-3 gap-6">
    <div class="card p-5"><h3 class="text-base font-semibold text-white mb-2">Roster by tier</h3>__TIERBARS__
      <p class="text-xs text-slate-500 mt-2">T2 carries __NT2__ of __NEL__ (consolidated 2026-06-12: T1 pairs overlap onto shared results). T4 (10) is the apex.</p></div>
    <div class="card p-5"><h3 class="text-base font-semibold text-white mb-2">Elements per family</h3>__FAMBARS__</div>
    <div class="card p-5"><h3 class="text-base font-semibold text-white mb-2">Status usage (how many elements apply each)</h3>__STATBARS__
      <p class="text-xs text-slate-500 mt-2">⚙ = also modifies the status's rule. The most-applied statuses are the de-facto win conditions.</p></div>
  </div>
  <div class="grid md:grid-cols-2 gap-6 mt-6">
    <div class="card p-5"><h3 class="text-base font-semibold text-white mb-2">Ability triggers (T2+)</h3>__TRIGBARS__
      <p class="text-xs text-slate-500 mt-2">Distribution of how abilities fire. Periodic + combat_start dominate; reactive (on_burn/on_leech/…) chains are the synergy glue.</p></div>
    <div class="card p-5"><h3 class="text-base font-semibold text-white mb-2">Reading the numbers</h3>
      <table class="k text-sm"><tr><th>In-degree</th><td>how many recipes PRODUCE this element → low = single-gated discovery, high = many redundant paths</td></tr>
      <tr><th>Out-degree</th><td>how many recipes this element FEEDS as an ingredient → your "feeds 7–8 combos" axis</td></tr>
      <tr><th>DD</th><td>damage-dealer: one of the __NDD__ that deal a direct hit (everything else's status IS its damage)</td></tr>
      <tr><th>Family</th><td>dominant Tier-1 root traced through the recipe tree (colouring aid)</td></tr></table></div>
  </div>
</section>

<!-- GRAPH -->
<section id="graph-sec" class="mb-12">
  <h2 class="text-2xl font-bold text-indigo-300 border-b border-indigo-900 pb-2 mb-4">② Forge network graph</h2>
  <p class="text-slate-400 mb-3">Every node is an element; every edge is "ingredient → result". <strong>Node size = total recipe load (in + out degree)</strong> — big nodes are forge hubs. Gold ring = damage-dealer. Toggle the colouring between <em>tier</em> and <em>family</em>, filter tiers, or search.</p>
  <div class="card p-3 mb-3 flex flex-wrap items-center gap-2">
    <span class="text-xs text-slate-400 mr-1">Colour:</span>
    <button class="ctrlbtn on" id="modeTier">By tier</button>
    <button class="ctrlbtn" id="modeFam">By family</button>
    <span class="w-px h-5 bg-slate-700 mx-1"></span>
    <span class="text-xs text-slate-400 mr-1">Tiers:</span>
    <button class="ctrlbtn on" data-tierf="1">T1</button>
    <button class="ctrlbtn on" data-tierf="2">T2</button>
    <button class="ctrlbtn on" data-tierf="3">T3</button>
    <button class="ctrlbtn on" data-tierf="4">T4</button>
    <span class="w-px h-5 bg-slate-700 mx-1"></span>
    <button class="ctrlbtn on" id="physBtn">Physics: on</button>
    <input id="search" placeholder="highlight element…" class="ml-1" oninput="doSearch(this.value)">
    <span class="flex-1"></span>
    <span class="text-xs text-slate-500" id="legend"></span>
  </div>
  <div id="graph"></div>
  <p class="text-xs text-slate-500 mt-2">Tier legend: <span style="color:#38bdf8">●T1</span> <span style="color:#34d399">●T2</span> <span style="color:#a78bfa">●T3</span> <span style="color:#f59e0b">●T4</span> &nbsp;·&nbsp; Family legend: __FAMLEGEND__</p>
</section>

<!-- IMBALANCE -->
<section id="imbalance" class="mb-12">
  <h2 class="text-2xl font-bold text-rose-300 border-b border-rose-900 pb-2 mb-4">③ Recipe imbalance — convergence vs reach</h2>
  <div class="grid lg:grid-cols-2 gap-6">
    <div class="card p-5">
      <h3 class="text-lg font-semibold text-white mb-2">Convergence — how many recipes MAKE each result</h3>
      <p class="text-xs text-slate-500 mb-2"><span class="text-rose-300">red ≥4 (over-served)</span> · <span class="text-amber-200">amber =1 (single-gated)</span>. T2+ only.</p>
      <div style="max-height:520px;overflow:auto"><table class="k text-sm"><tr><th>Result</th><th>Tier</th><th>#paths</th><th>Recipes</th></tr>__CONVROWS__</table></div>
    </div>
    <div class="card p-5">
      <h3 class="text-lg font-semibold text-white mb-2">Reach — most-used ingredients (T2+)</h3>
      <p class="text-xs text-slate-500 mb-2">High out-degree = this element is an ingredient in many recipes. (T1 trivially feed everything — 12 each — so this lists T2+ only.)</p>
      <table class="k text-sm"><tr><th>Ingredient</th><th>Tier</th><th>#recipes</th><th>#results</th><th>Feeds into</th></tr>__REACHROWS__</table>
      <p class="text-xs text-slate-400 mt-3">💧/🔥/🌬️/🌍 and the rest of T1 each feed <strong>12</strong> recipes — the widest hubs, by design (every T1 crosses the original four + a self-combo + blood/frost crosses).</p>
    </div>
  </div>
</section>

<!-- ROSTER -->
<section id="roster" class="mb-12">
  <h2 class="text-2xl font-bold text-emerald-300 border-b border-emerald-900 pb-2 mb-4">④ Full element roster</h2>
  <div class="card p-3 mb-3 flex flex-wrap items-center gap-2">
    <input id="rfilter" placeholder="filter name/id…" oninput="filterRoster()">
    <span class="text-xs text-slate-400 ml-2">Tier:</span>
    <button class="ctrlbtn on rtier" data-t="1">T1</button><button class="ctrlbtn on rtier" data-t="2">T2</button>
    <button class="ctrlbtn on rtier" data-t="3">T3</button><button class="ctrlbtn on rtier" data-t="4">T4</button>
    <button class="ctrlbtn ml-2" id="ddOnly">Damage-dealers only</button>
    <button class="ctrlbtn" id="abOnly">Has ability only</button>
    <span class="flex-1"></span><span class="text-xs text-slate-500" id="rcount"></span>
  </div>
  <div class="card p-2" style="max-height:760px;overflow:auto">
    <table class="k text-sm" id="roster">
      <thead><tr>
        <th class="sortable" data-c="0">Element</th><th class="sortable" data-c="1">Tier</th>
        <th class="sortable" data-c="2">Family</th><th class="sortable" data-c="3" title="recipes that make it">In</th>
        <th class="sortable" data-c="4" title="recipes it feeds">Out</th><th class="sortable" data-c="5">CD</th>
        <th class="sortable" data-c="6" title="effective direct damage at Lv1">Dmg</th><th class="sortable" data-c="7">Trigger</th>
        <th>Applies</th><th>Ability</th>
      </tr></thead><tbody>__ROSTERROWS__</tbody>
    </table>
  </div>
</section>

<!-- DAMAGE DEALERS -->
<section id="dd" class="mb-12">
  <h2 class="text-2xl font-bold text-amber-300 border-b border-amber-900 pb-2 mb-4">⑤ Damage-dealers (the only direct-hit elements)</h2>
  <div class="card p-5">
    <p class="text-slate-400 mb-3 text-sm">__NDD__ of __NEL__. <span class="mono">effective_damage = base × level × tier multiplier (1/1.5/2.5/3.5)</span>. Everyone else returns 0 — their status carries the damage. Lv1/2/3 columns show how the hit scales with merges.</p>
    <table class="k text-sm"><tr><th>Element</th><th>Tier</th><th>Family</th><th>Base</th><th>Lv1</th><th>Lv2</th><th>Lv3</th><th>CD</th><th>Ability</th></tr>__DDROWS__</table>
  </div>
</section>

<!-- MECHANICS -->
<section id="mech" class="mb-12">
  <h2 class="text-2xl font-bold text-violet-300 border-b border-violet-900 pb-2 mb-4">⑥ Status & ability mechanics — how each one works</h2>
  <div class="card p-5">
    <p class="text-slate-400 mb-3 text-sm">The functional behaviour pulled from <span class="mono">StatusSystem.gd</span>. Status is a flat per-side pool shared by every element on that side; <strong>potency = the applying element's Level</strong> (a Lv-N element applies N stacks). Magnitudes are mostly ×1 placeholders for the balance pass.</p>
    <table class="k"><tr><th>Status</th><th>Type</th><th>Magnitude</th><th>How it actually works</th></tr>__GLOSSROWS__</table>
  </div>
  <div class="card p-5 mt-6">
    <h3 class="text-lg font-semibold text-white mb-2">Trigger vocabulary</h3>
    <table class="k text-sm">
      <tr><th>combat_start</th><td>fires once at t=0 — reserved for TRUE setup since the 2026-06-12 rebalance: walls (boulder/brick), freezes (glacier/iceage), deep curse (void/voidrift), max-HP bulk (ironwood/ancientgrove).</td></tr>
      <tr><th>periodic</th><td>first fire at +interval, then every interval. Capped at 3 iconic engines (lava, volcano, rainbow) — the element's own cooldown already provides "every X seconds", so on_activate carries that rhythm now.</td></tr>
      <tr><th>passive</th><td>queried at the calc site — modifies a rule for the whole combat (Blaze burn+1, Plasma shock+3, Acid armor-no-regen, Tempest cleanse-proof shock) or carries an adjacency aura (Root/Obsidian/Primordial).</td></tr>
      <tr><th>passive_on_hit</th><td>% roll on every damage hit (seeded RNG) — Dust/Static/Flint/Pollen/Sand/Haze sprinkle a status.</td></tr>
      <tr><th>on_activate</th><td>each fire (optional every_n gate, optional multicast) — the workhorse trigger post-rebalance: rides the element's own cooldown. Build-up payoffs (Tsunami every 4th, Supernova every 3rd) create timing decisions.</td></tr>
      <tr><th>on_* reactive</th><td>depth-1 reaction to an event: on_burn_applied, on_heal_applied, on_leech, on_damage_dealt, on_poison_tick, on_burn_tick, on_armor_stripped, on_haste_applied, on_status_applied. The synergy chains — now ~1/3 of the roster.</td></tr>
    </table>
    <p class="text-xs text-slate-500 mt-2">Multicast (×2 at T2/T3, ×3 at T4) repeats the whole fire, each repeat an independent reactive trigger. Reactives never re-trigger reactives (depth-1).</p>
  </div>
</section>

<!-- OBSERVATIONS -->
<section id="obs" class="mb-12">
  <h2 class="text-2xl font-bold text-slate-200 border-b border-slate-700 pb-2 mb-4">⑦ Flagged observations (mine — push back on these)</h2>
  <div class="grid lg:grid-cols-2 gap-5">__OBSCARDS__</div>
  <p class="text-xs text-slate-500 mt-4">These are starting points for your feedback, not verdicts. The data tables above are neutral; this section is where I'm guessing at what might want changing.</p>
</section>

<footer class="text-xs text-slate-600 border-t border-slate-800 pt-4 mt-8">
  Generated from live data __DATE__ · ElementData.gd · RecipeData.gd · AbilityData.gd · EffectRegistry.gd · StatusSystem.gd · rebuild via <span class="mono">_build_elements_review.py</span>.
</footer>
</div>

<script>
const NODES=__NODES__, EDGES=__EDGES__;
let mode="tier", physics=true;
const tierOn={1:true,2:true,3:true,4:true};
function nodeColor(n){const c = mode==="tier"?n.tierColor:n.famColor;
  return {background:c+"cc", border:(n.dd?"#fde047":c), highlight:{background:c,border:"#fff"}};}
const ds=new vis.DataSet(NODES.map(n=>({id:n.id,label:n.label,value:n.value,title:n.title,
  hidden:!tierOn[n.tier], color:nodeColor(n), borderWidth:n.dd?3:1,
  font:{color:"#e2e8f0",size:13,face:"ui-sans-serif"}})));
const es=new vis.DataSet(EDGES.map((e,i)=>({id:i,from:e.from,to:e.to})));
const container=document.getElementById("graph");
const network=new vis.Network(container,{nodes:ds,edges:es},{
  nodes:{shape:"dot",scaling:{min:8,max:42,label:{enabled:true,min:11,max:20}}},
  edges:{arrows:{to:{enabled:true,scaleFactor:0.4}},color:{color:"#33415577",highlight:"#94a3b8"},
         smooth:{type:"continuous"},width:0.6},
  physics:{enabled:true,solver:"forceAtlas2Based",
    forceAtlas2Based:{gravitationalConstant:-45,centralGravity:0.008,springLength:90,springConstant:0.05,damping:0.5},
    stabilization:{iterations:220}},
  interaction:{hover:true,tooltipDelay:120,navigationButtons:true,keyboard:false}
});
function recolor(){ds.update(NODES.filter(n=>tierOn[n.tier]).map(n=>({id:n.id,color:nodeColor(n),borderWidth:n.dd?3:1})));}
function refilter(){ds.update(NODES.map(n=>({id:n.id,hidden:!tierOn[n.tier]})));}
document.getElementById("modeTier").onclick=()=>{mode="tier";setMode();};
document.getElementById("modeFam").onclick=()=>{mode="family";setMode();};
function setMode(){document.getElementById("modeTier").classList.toggle("on",mode==="tier");
  document.getElementById("modeFam").classList.toggle("on",mode==="family");
  document.getElementById("legend").textContent = mode==="tier"?"sized by recipe load":"grouped by lineage";
  recolor();}
document.querySelectorAll("[data-tierf]").forEach(b=>b.onclick=()=>{const t=+b.dataset.tierf;
  tierOn[t]=!tierOn[t];b.classList.toggle("on",tierOn[t]);refilter();});
document.getElementById("physBtn").onclick=function(){physics=!physics;network.setOptions({physics:{enabled:physics}});
  this.classList.toggle("on",physics);this.textContent="Physics: "+(physics?"on":"off");};
function doSearch(q){q=q.trim().toLowerCase();
  ds.update(NODES.filter(n=>tierOn[n.tier]).map(n=>{const hit=q&&(n.id.includes(q)||n.label.toLowerCase().includes(q));
    const c=nodeColor(n); return {id:n.id,borderWidth:hit?4:(n.dd?3:1),
      color:{background:c.background,border:hit?"#f472b6":c.border,highlight:c.highlight}};}));}
network.once("stabilizationIterationsDone",()=>network.setOptions({physics:{enabled:physics}}));
setMode();

// roster sort + filter
const tbody=document.querySelector("#roster tbody");
let sortCol=-1,sortDir=1;
document.querySelectorAll("#roster th.sortable").forEach(th=>th.onclick=()=>{
  const c=+th.dataset.c; sortDir=(c===sortCol)?-sortDir:1; sortCol=c;
  const rows=[...tbody.querySelectorAll("tr")];
  rows.sort((a,a2)=>{const x=cell(a,c),y=cell(a2,c); return (x<y?-1:x>y?1:0)*sortDir;});
  rows.forEach(r=>tbody.appendChild(r));
});
function cell(tr,c){const td=tr.children[c];const s=td.dataset.sort;return s!==undefined?+s:td.textContent.trim().toLowerCase();}
const rTierOn={1:true,2:true,3:true,4:true};let ddOnly=false,abOnly=false;
document.querySelectorAll(".rtier").forEach(b=>b.onclick=()=>{const t=+b.dataset.t;rTierOn[t]=!rTierOn[t];b.classList.toggle("on",rTierOn[t]);filterRoster();});
document.getElementById("ddOnly").onclick=function(){ddOnly=!ddOnly;this.classList.toggle("on",ddOnly);filterRoster();};
document.getElementById("abOnly").onclick=function(){abOnly=!abOnly;this.classList.toggle("on",abOnly);filterRoster();};
function filterRoster(){const q=document.getElementById("rfilter").value.trim().toLowerCase();let n=0;
  tbody.querySelectorAll("tr").forEach(tr=>{const t=+tr.dataset.tier;
    const ok=rTierOn[t]&&(!ddOnly||tr.dataset.dd==="1")&&(!abOnly||tr.dataset.ab==="1")&&(!q||tr.dataset.name.includes(q));
    tr.style.display=ok?"":"none"; if(ok)n++;});
  document.getElementById("rcount").textContent=n+" shown";}
filterRoster();
</script>
</body></html>"""

repl = {
 "__NEL__":str(len(elements)), "__NRE__":str(len(recipes)),
 "__NAB__":str(len([a for a in abilities.values() if a.get('trigger')])), "__NDD__":str(len(damage_dealers)),
 "__NT2__":str(sum(1 for e in elements if e["tier"]==2)),
 "__TIERBARS__": bar_rows(Counter({f'{TIER_NAME[t]} ({TIER_NAME[t]})':c for t,c in tier_counts.items()}), "#6366f1", fmt=lambda k:k),
 "__FAMBARS__": bar_rows(fam_counts, "#a78bfa"),
 "__STATBARS__": bar_rows(status_usage, "#f472b6", fmt=lambda k:f'{STATUS_EMOJI.get(k,"")} {k}'),
 "__TRIGBARS__": bar_rows(trigger_counts, "#22d3ee"),
 "__FAMLEGEND__": FAM_LEGEND,
 "__CONVROWS__": "".join(conv_rows),
 "__REACHROWS__": "".join(reach_rows),
 "__ROSTERROWS__": "".join(roster_rows),
 "__DDROWS__": "".join(dd_rows),
 "__GLOSSROWS__": "".join(gloss_rows),
 "__OBSCARDS__": "".join(OBS),
 "__NODES__": NODES_JSON, "__EDGES__": EDGES_JSON,
 "__DATE__": TODAY_DASH,
}
# fix tier bar labels (avoid double name)
repl["__TIERBARS__"] = bar_rows(Counter({TIER_NAME[t]:c for t,c in tier_counts.items()}), "#6366f1")
for k,v in repl.items():
    html = html.replace(k,v)

OUT.write_text(html, encoding="utf-8")
print("wrote", OUT, len(html), "bytes")
print("single-path T3:", single_t3)
print("single-path T4:", single_t4)
print("over-converged:", [(r['id'],r['inDeg']) for r in overconv])
print("dupe ability groups:", dupe_groups)
print("empty-effect:", empty_eff)
print("fams_no_dd:", fams_no_dd)
