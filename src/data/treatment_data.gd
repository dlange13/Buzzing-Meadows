class_name TreatmentData
extends Resource

## TreatmentData — Resource defining a varroa mite treatment option.
## Designed to be saved as a .tres file and referenced by HiveManager.
##
## Each treatment has real-world accuracy requirements baked in:
## - Oxalic Acid: >97% effectiveness but ONLY works on phoretic (non-reproducing)
##   mites, meaning it requires a brood-free hive to be truly effective.
## - Apivar (amitraz): ~90% effective; works in brood; 42–56 day treatment.
## - Apiguard (thymol): ~74% effective; temperature-sensitive (>60°F required).
## - HopGuard (hop beta acids): ~65%; safe with honey supers on.

@export var treatment_name: String = ""
@export var active_ingredient: String = ""
## Mite kill rate from 0.0 (ineffective) to 1.0 (100% kill). Applied to phoretic
## mites (those on adult bees). Mites in capped brood are protected from most treatments.
@export var effectiveness: float = 0.9       # 0.0–1.0 mite kill rate
## If true, this treatment only kills phoretic mites (on adult bees) and is
## ineffective against mites in capped brood cells. Most effective in winter or
## during a brood break when no capped brood is present.
@export var requires_brood_free: bool = false
## Duration in in-game days the treatment must remain in the hive.
## Removing early reduces effectiveness.
@export var duration_days: int = 0
## Whether honey supers can safely remain on during treatment.
## If false, supers must be removed before treatment and not added until complete.
## This is a real-world regulatory requirement (residue contamination in honey).
@export var safe_with_honey_supers: bool = false   # can honey supers stay on during treatment?
## Educational note displayed to the player when selecting this treatment.
## Should explain the beekeeping science behind usage requirements.
@export var educational_note: String = ""
