class_name EffectRegistry

# Single source of truth for per-effect metadata consumed by StatusSystem,
# AbilitySystem, and any future Compendium / Tooltip reader.
#
# status_shape: initial dict written into StatusSystem.empty_statuses().
#               {} means no persistent status (heal, cleanse are instant-only).
# count_field:  the headline field read by AbilitySystem._status_count() for
#               "target_has_status" conditions. "" = not condition-testable.
# triggers:     trigger strings emitted when this effect fires on a hit.
#               on_damage_dealt is excluded — it depends on damage amount,
#               not the effect name, and is appended at the call site.
const EFFECTS: Dictionary = {
	"burn":    { "status_shape": { "stacks": 0, "tick_damage_bonus": 0 },                    "count_field": "stacks",          "triggers": ["on_burn_applied", "on_status_applied:burn"] },
	"poison":  { "status_shape": { "stacks": 0, "tick_damage_bonus": 0 },                    "count_field": "stacks",          "triggers": ["on_status_applied:poison"] },
	"armor":   { "status_shape": { "value": 0, "floor": 0 },                                 "count_field": "value",           "triggers": [] },
	"plating": { "status_shape": { "value": 0, "reduces_dot": false },                       "count_field": "value",           "triggers": [] },
	"blind":   { "status_shape": { "percent": 0 },                                           "count_field": "percent",         "triggers": ["on_status_applied:blind"] },
	"shock":   { "status_shape": { "n": 0, "effective_stack_bonus": 0 },                     "count_field": "n",               "triggers": ["on_status_applied:shock"] },
	"slow":    { "status_shape": { "n": 0 },                                                 "count_field": "n",               "triggers": [] },
	"haste":   { "status_shape": { "reduction": 0, "reduction_bonus_deciseconds": 0 },       "count_field": "reduction",       "triggers": ["on_haste_applied"] },
	"weaken":  { "status_shape": { "stacks": 0, "ticks": 0, "duration_bonus": 0 },          "count_field": "stacks",          "triggers": ["on_status_applied:weaken"] },
	"curse":   { "status_shape": { "ticks_remaining": 0, "is_permanent": false, "damage_amplifier": 0 }, "count_field": "ticks_remaining", "triggers": ["on_status_applied:curse"] },
	"leech":   { "status_shape": { "bonus": 0, "double": false },                            "count_field": "",                "triggers": ["on_leech"] },
	"heal":    { "status_shape": {},                                                          "count_field": "",                "triggers": ["on_heal_applied"] },
	"cleanse": { "status_shape": {},                                                          "count_field": "",                "triggers": [] },
}
