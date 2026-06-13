extends Control


func _ready() -> void:
	$Margin/VBox/Title.add_theme_color_override("font_color", ThemeData.COLOR_TITLE)
	var rtl: RichTextLabel = $Margin/VBox/Scroll/Content
	UIScale.apply_rich(rtl, 15)
	rtl.text = _build_content()


static func _build_content() -> String:
	return (
		"[color=#bf8cff][b]WHAT IS THIS?[/b][/color]\n"
		+ "Build a board of Elements and fight [b]ghost boards[/b] — snapshots of other players' "
		+ "builds from past runs. Eventually this becomes async PvP. "
		+ "[b]Win 10 rounds[/b] to win. Drop to [b]0 Life[/b] and you're eliminated.\n\n"

		+ "[color=#bf8cff][b]YOUR LIFE[/b][/color]\n"
		+ "Start at 100. Win → they bleed. Lose → you lose Life proportional to the opponent's "
		+ "remaining HP. Draw = win for you. 0 Life = out.\n\n"

		+ "[color=#bf8cff][b]THE SHOP[/b][/color]\n"
		+ "Each round starts here. Earn [b]+10 gold[/b] per round.\n"
		+ "• Buy Elements (5–16g by tier)\n"
		+ "• Reroll 5 shop slots for 2g (cost rises each reroll this phase)\n"
		+ "• Drag Elements to your [b]Battle Grid[/b] — those fight. Inventory holds extras.\n\n"

		+ "[color=#bf8cff][b]ELEMENTS[/b][/color]\n"
		+ "Each Element fires its [b]Ability[/b] automatically on a cooldown timer. "
		+ "Higher tier = stronger effect.\n\n"
		+ "[b]12 base elements (T1 — 5g each)[/b]\n"
		+ "💧 Water [i](Cleanse)[/i]  🔥 Fire [i](Burn)[/i]  🌬️ Air [i](Haste)[/i]  🌍 Earth [i](Armor)[/i]\n"
		+ "⚡ Lightning [i](Shock)[/i]  🌿 Nature [i](Heal)[/i]  ☀️ Light [i](Blind)[/i]  🌑 Dark [i](Curse)[/i]\n"
		+ "⚙️ Metal [i](Plating)[/i]  🍄 Fungus [i](Poison)[/i]  🩸 Blood [i](Leech)[/i]  🌨️ Frost [i](Weaken)[/i]\n\n"
		+ "Higher tiers unlock by forging:  [color=#8cccff]T2 — 8g[/color]  ·  "
		+ "[color=#c87cff]T3 — 12g[/color]  ·  [color=#f5bd33]T4 — 16g[/color]\n\n"

		+ "[color=#bf8cff][b]MERGE & FORGE[/b][/color]\n"
		+ "[b]Merge[/b] — drag two copies of the [i]same[/i] Element at the same level together → Level +1. Free.\n"
		+ "[b]Forge[/b] — drag two [i]different[/i] Elements (both Lv2+) to the Forge Bench → higher-tier result. "
		+ "Hover an element to see what it forges with.\n\n"

		+ "[color=#bf8cff][b]STATUS EFFECTS[/b][/color]\n"
		+ "[b]Debuffs:[/b] 🔥 Burn [i](ramping tick dmg)[/i] · 🍄 Poison [i](permanent stacks)[/i] · "
		+ "☀️ Blind [i](miss chance)[/i] · 🌑 Curse [i](amplify all hits)[/i] · "
		+ "🌨️ Weaken [i](cut attacker dmg)[/i] · ⚡ Shock [i](slow cooldowns)[/i]\n"
		+ "[b]Buffs:[/b] 🌍 Armor [i](absorb dmg)[/i] · ⚙️ Plating [i](flat reduction)[/i] · "
		+ "🌿 Heal [i](regen)[/i] · 🌬️ Haste [i](faster CD)[/i] · 🩸 Leech [i](heal on hit)[/i]\n\n"

		+ "[color=#bf8cff][b]BATTLE[/b][/color]\n"
		+ "Elements fire automatically. After [b]30 seconds[/b] the Sandstorm starts — "
		+ "escalating [b]true damage[/b] to both sides every second until someone is eliminated.\n\n"

		+ "[color=#bf8cff][b]STARTING PICK (KEYSTONE)[/b][/color]\n"
		+ "At the start of every run, pick [b]1 of 4 Keystones[/b]. "
		+ "Powerful passives that scale with your board — commit to a strategy and build around it.\n\n"

		+ "[color=#bf8cff][b]EVENTS[/b][/color]\n"
		+ "Every [b]3 rounds[/b], before the Shop, choose 1 of 3 offers: "
		+ "gold · free Element · run modifier (Augment).\n\n"

		+ "[color=#bf8cff][b]GRID GROWTH[/b][/color]\n"
		+ "Your battle grid starts 2×2 (4 slots). Forge or merge an Element to Lv2+ at T2 or higher "
		+ "and earn a new slot — up to 6 in a normal run.\n\n"

		+ "[color=#bf8cff][b]QUICK REFERENCE[/b][/color]\n"
		+ "[table=2]"
		+ "[cell][b]Action[/b][/cell][cell][b]Cost[/b][/cell]"
		+ "[cell]Buy T1 / T2 / T3 / T4[/cell][cell]5g / 8g / 12g / 16g[/cell]"
		+ "[cell]Reroll shop[/cell][cell]2g (rises per reroll)[/cell]"
		+ "[cell]Merge (same element, same level)[/cell][cell]Free[/cell]"
		+ "[cell]Forge (two different, both Lv2+)[/cell][cell]Free[/cell]"
		+ "[cell]Sell element[/cell][cell]Half buy price[/cell]"
		+ "[/table]"
	)


func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
