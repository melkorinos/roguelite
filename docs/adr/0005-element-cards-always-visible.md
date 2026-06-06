# Always-visible Element Cards instead of hover-only tooltips

Every auto-battler in the genre (TFT, Hearthstone Battlegrounds, Super Auto Pets) gates element detail behind a hover gesture. We are deliberately breaking that pattern: each slot renders a full Element Card at all times — icon, stats, and Ability text — with no interaction required to see them. The reasoning is that Abilities are not peripheral flavour; they are the primary strategic layer of the game, and forcing the player to hover-discover them one by one creates friction that works against the "master the meta over dozens of sessions" goal. Screen real estate at 1920×1080 makes the trade-off acceptable.

The floating Item Tooltip is not removed — it is repurposed to show live per-element combat statistics (fires, damage, effects, HP healed) on hover during the battle phase only.
