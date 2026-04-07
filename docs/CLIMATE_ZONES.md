# Climate Zones — Buzzing Meadows

This document describes the planned climate zones for Buzzing Meadows and how each
affects beekeeping mechanics, seasonal timing, and available pollinators.

---

## Overview

Climate zones in Buzzing Meadows alter the **timing and intensity** of seasonal
events, the **available nectar plants and bloom windows**, **varroa growth rates**,
and **unique challenges** (heat stress, Africanized bee risk, SHB pressure, etc.).

Each zone is modeled on a real geographic region's actual beekeeping practices.

---

## Zone 1: Temperate Midwest — Wisconsin (MVP Zone)

**Real-World Region:** Upper Midwest USA (Wisconsin, Minnesota, Michigan, Iowa)  
**Climate Type:** Humid Continental  
**Season Length:** Spring 8 weeks, Summer 8 weeks, Fall 8 weeks, Winter 20 weeks  

**Key Nectar Sources:**
- Maple (early spring pollen)
- Dandelion (first major spring nectar)
- White Clover (*Trifolium repens*) — primary summer flow
- Basswood / American Linden (*Tilia americana*) — premium summer honey
- Goldenrod (*Solidago* spp.) — critical fall stores
- Aster — late fall supplement

**Unique Challenges:**
- Hard winters (-20°F possible); strong winter colonies required
- Nectar dearth in August → varroa and robbing spike
- Soybean and corn farmland reduces wildflower diversity
- Late frost risk into May can kill spring foragers

**Critical Calendar Dates:**
- August 15: Varroa treatment deadline (protect winter bees)
- October 15: Mouse guards, entrance reduction
- December–January: Oxalic acid brood-free treatment window
- March–April: First spring inspection

**In-Game Modifiers:**
- `varroa_growth_multiplier` peaks at 1.8× in July (maximum brood)
- Winter survival requires ≥60 lbs honey stores or starvation event fires
- Long winter cluster period (85 days)

---

## Zone 2: Pacific Northwest — Oregon/Washington (Year 2)

**Real-World Region:** Pacific Coast USA/Canada (Oregon, Washington, British Columbia)  
**Climate Type:** Oceanic  
**Season Length:** Spring 10 weeks, Summer 10 weeks, Fall 6 weeks, Winter 14 weeks  

**Key Nectar Sources:**
- Bigleaf Maple (*Acer macrophyllum*) — massive early pollen
- Blackberry (*Rubus* spp.) — major summer honey
- Fireweed (*Chamerion angustifolium*) — premium late-summer flow
- English Ivy (*Hedera helix*) — late fall (invasive but bees use it)
- Red Alder (early pollen)

**Unique Challenges:**
- Wet, cold springs; bees confined → Nosema risk
- Robbing pressure from wasps (yellowjackets/hornets) in August
- Varroa + Nosema combination particularly dangerous in wet falls
- Less extreme winter; colonies can remain active longer

**Critical Calendar Dates:**
- September 1: Varroa treatment deadline
- November–December: Oxalic acid window
- April: First real inspection (may be later than Midwest due to wet weather)

**In-Game Modifiers:**
- Spring wet event fires more frequently
- Nosema mechanic (reduces foraging efficiency) present
- Lower winter store threshold required (milder winters)
- Fireweed bloom event gives large honey bonus (late July/August)

---

## Zone 3: Desert Southwest — Arizona/New Mexico (Year 2)

**Real-World Region:** Southwest USA (Arizona, New Mexico, Southern California, Nevada)  
**Climate Type:** Semi-arid / Desert  
**Season Length:** Two-peak structure (Spring flow + Fall flow); summer rest period  

**Key Nectar Sources:**
- Saguaro Cactus (*Carnegiea gigantea*) — major spring source
- Palo Verde (*Parkinsonia* spp.) — spring
- Mesquite (*Prosopis* spp.) — spring
- Desert Willow — summer
- Desert Marigold — fall

**Unique Challenges:**
- **Heat Stress** (110°F+ in July/August): Colonies reduce population; risk of comb melt
- **Africanized Bee Risk**: European colonies may hybridize with Africanized bees;
  requeening with European genetics is critical management
- Summer nectar dearth is extreme — almost no foraging July/August
- Year-round foraging possible but interrupted by heat
- No hard winter; colonies may not produce winter cluster

**Critical Calendar Dates:**
- March–May: Primary nectar flow; harvest spring honey
- June: Prepare for heat period; add ventilation; provide water
- September: Second buildup begins as temps moderate
- November: Treat varroa before second brood buildup ends

**In-Game Modifiers:**
- Two-peak honey production seasons (spring and fall)
- Heat event mechanic: if temperature >105°F (in-game day modifier), colony reduces
  to 50% population for 5 days; comb may soften in Flow Hives
- Africanized genetics mechanic: if colony becomes defensive beyond threshold,
  requeening quest triggers
- No hard winter; minimal winter stores required

---

## Zone 4: Southeastern US — Georgia/Florida/Carolinas (Year 3)

**Real-World Region:** Southeastern USA (Georgia, Florida, Tennessee, Carolinas)  
**Climate Type:** Humid Subtropical  
**Season Length:** Very long active season; mild winter  

**Key Nectar Sources:**
- Tulip Poplar (*Liriodendron tulipifera*) — massive early spring flow (best honey)
- Gallberry (*Ilex glabra*) — premium southeastern honey
- Tupelo (*Nyssa* spp.) — rare; prized specialty honey
- Sourwood (*Oxydendrum arboreum*) — rare mountain honey
- Wildflower mix year-round

**Unique Challenges:**
- **Small Hive Beetle (SHB)** (*Aethina tumida*): Major pest; warm climate allows
  year-round reproduction; can destroy weak colonies within days
- High humidity → wax moth pressure
- Summer dearth July–August
- Hurricane/tropical storm events (coastal regions)
- Fire ant nest interference with hives on the ground

**Critical Calendar Dates:**
- February: First spring inspection; colonies may already be building rapidly
- April–May: Tulip poplar flow → major honey harvest
- July–August: Summer dearth; SHB pressure peaks
- October–November: Treat varroa; light winterization

**In-Game Modifiers:**
- SHB mechanic: SHB population tracked per hive; weak colonies at risk of SHB
  larvae infestation (destroys frames); beetle traps reduce risk
- Very early spring (February) first inspection date
- No major winter cluster event
- Hurricane event (random; causes hive knockover; requires uprighting and inspection)

---

## Zone 5: Northern Europe — Scandinavia/Northern UK (Year 3)

**Real-World Region:** Northern Europe (Norway, Sweden, Finland, Scotland, Ireland)  
**Climate Type:** Subarctic / Maritime  
**Season Length:** Spring 6 weeks, Summer 8 weeks, Fall 4 weeks, Winter 26 weeks  

**Key Nectar Sources:**
- Heather (*Calluna vulgaris*) — premium monofloral heather honey
- White Clover — short summer window
- Rapeseed / Canola (*Brassica napus*) — major spring flow
- Willowherb / Fireweed — summer
- Linden — limited availability

**Unique Challenges:**
- **Very short active season** — only ~18 weeks total
- Very long winter cluster (26 weeks+)
- Heather honey is thixotropic — special harvesting required (press extraction)
- Cold, wet summers reduce foraging days significantly
- Isle of Man / isolated populations may have local bee ecotypes (e.g., black bee,
  *Apis mellifera mellifera*)

**Critical Calendar Dates:**
- May–June: First real inspection (very late spring)
- August: Heather flow (brief); major honey harvest
- August 1: Varroa treatment deadline (even shorter season than Midwest)
- October: Winterization complete
- December–January: Oxalic acid treatment

**In-Game Modifiers:**
- Shortest available active season; tight management windows
- Heather honey mechanic: special harvesting tool required; premium sell price
- High winter store requirement (26-week winter = 80+ lbs honey needed)
- Rain event fires frequently in spring/summer; reduces foraging efficiency
- Black bee ecotype available as special in-game breed (adapted to cold, frugal stores)

---

## Technical Implementation Notes

Each climate zone is implemented as a `ClimateZoneConfig` Resource (planned) with:
- Season duration overrides
- Nectar source list and bloom windows
- Unique event pool and probabilities
- `varroa_growth_multiplier` curves per season
- Minimum winter store thresholds
- Unique mechanic flags (SHB enabled, Africanized risk enabled, etc.)

Climate zones are unlocked progressively through gameplay to teach players about
regional beekeeping variation without overwhelming new players.
