class_name BeeSpeciesData
extends Resource

## BeeSpeciesData — Resource defining a single pollinator species.
## Designed to be saved as a .tres file and registered with PollinatorRegistry.
##
## Each species has real-world biological data paired with in-game attraction logic.
## When discovered by the player, the species unlocks a museum fact card entry.

@export var common_name: String = ""
@export var scientific_name: String = ""
## Rarity tier: Common / Uncommon / Rare / Seasonal
## Seasonal = only discoverable during specific in-game seasons.
@export var rarity: String = "Common"        # Common/Uncommon/Rare/Seasonal
## Path to the species' sprite sheet (res:// relative).
@export var sprite_path: String = ""
## 1–2 sentences of accurate real-world biology shown in the museum fact card.
@export var educational_fact: String = ""
## Plants in the garden that attract this species (plant common names as Strings).
## Example: ["White Clover", "Lavender", "Bee Balm"]
@export var preferred_plants: Array[String] = []
## Seasons in which this species is active and can be discovered.
## Valid values: "Spring", "Summer", "Fall", "Winter"
@export var active_seasons: Array[String] = []
## Climate zones where this species can be found.
## Valid values match ClimateZoneConfig.zone_id values.
@export var climate_zones: Array[String] = []
## Whether the player has discovered this species yet.
## Set to true by PollinatorRegistry when first encountered.
@export var discovered: bool = false
