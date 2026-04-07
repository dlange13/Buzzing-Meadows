class_name SeasonConfig
extends Resource

## SeasonConfig — Resource defining the properties of a single in-game season.
## Designed to be saved as a .tres file and loaded by SeasonManager.
##
## Seasons drive the core gameplay loop: nectar flow, varroa pressure, and which
## tasks are available all change with the season. This follows real beekeeping
## calendars — varroa is a minor issue in winter (no brood) but explosive in summer.

## Display name for the season: "Spring", "Summer", "Fall", or "Winter"
@export var season_name: String = ""         # Spring/Summer/Fall/Winter
## Duration of this season in in-game days. Default 28 (4 weeks per season).
## Northern Europe zones have longer winters; Desert Southwest has no true winter.
@export var days_duration: int = 28
## True during the main nectar flow periods. When active, honey production accelerates
## and player should have supers on the hive. False in dearth periods and winter.
@export var nectar_flow_active: bool = false
## Multiplier applied to the base daily varroa reproduction rate.
## 1.0 = baseline; peaks at ~1.8 in summer (maximum brood = maximum mite reproduction);
## drops to 0.05 in winter (no brood = no mite reproduction, only phoretic mites survive).
@export var varroa_growth_multiplier: float = 1.0
## Multiplier on daily bee emergence that drives population dynamics.
## >1.0 = population growing (spring buildup); <1.0 = declining (fall/winter).
## Spring: 1.5, Summer: 1.0, Fall: 0.5, Winter: 0.1
@export var population_growth_multiplier: float = 1.0
## Nectar flow intensity from 0.0 (no flow) to 1.0 (full peak flow).
## Used to scale daily honey production when nectar_flow_active is true.
## Spring typically has a partial flow (0.6); summer is peak (1.0).
@export var nectar_flow_intensity: float = 1.0
## List of recommended player tasks this season (shown in the in-game task journal).
## Each String is a short task description, e.g. "Treat for varroa mites".
@export var recommended_tasks: Array[String] = []
## Pool of random events that can fire during this season.
## Each String is an event ID looked up by SeasonManager.
## Example: ["swarm_event", "nectar_dearth", "pesticide_event"]
@export var possible_events: Array[String] = []
