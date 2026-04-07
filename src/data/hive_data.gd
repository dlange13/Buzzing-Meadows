class_name HiveData
extends Resource

## HiveData — Resource representing the state of a single beehive.
## Designed to be saved as a .tres file and loaded by HiveManager.
##
## Varroa mite load is measured as mites per 100 bees (percentage).
## Real-world threshold: >3% = action required; >5% = critical; >8% = collapse risk.

@export var hive_type: String = "Langstroth"
## Current adult bee population. A healthy summer colony: 50,000–80,000 bees.
@export var population: int = 10000
## Whether a laying queen is present. Queenless colonies will decline within weeks.
@export var queen_present: bool = true
## Age of the current queen in in-game days. Queens older than ~730 days (2 seasons)
## may show reduced laying efficiency and should be considered for replacement.
@export var queen_age_days: int = 0
## Varroa mite load as mites per 100 bees (%). Doubles every 4–5 weeks in summer
## because mites reproduce inside capped brood cells. Treat when >2% in summer.
@export var varroa_mite_load: float = 0.0   # mites per 100 bees (>3% = critical)
## Honey stores in kilograms. A Langstroth colony needs ~27–36 kg (60–80 lbs) for
## a northern winter. Below 10 kg triggers starvation risk in winter.
@export var honey_stores_kg: float = 0.0
## Overall brood health, 0.0 (collapsed) to 1.0 (perfect). Degrades with high varroa
## load, disease, or queenlessness. Low brood health reduces population growth rate.
@export var brood_health: float = 1.0        # 0.0 to 1.0
## In-game day of last inspection. Colonies uninspected for >14 days may develop
## undetected problems. Regular inspection is core to good beekeeping practice.
@export var last_inspected_day: int = 0
## True if Africanized genetics are detected — colony will be more defensive.
## Requeening with European stock resolves this but takes time.
@export var is_defensive: bool = false       # true if Africanized genetics present
