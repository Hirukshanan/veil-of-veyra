# Existing Chapter I quest-system audit

Inspection occurred before implementation. This phase builds on the current persistent campaign; it does not replace it.

| System | Before Phase 6.1 | Phase 6.1 result |
| --- | --- | --- |
| Main progression | Functional. Five active camp wolves and three beach seal fragments, then manually light the northern lantern; existing Tidewraith encounter and victory. | Same AND prerequisite and manual interaction. One derived current-goal view now explains progress, guidance, reward and next step. |
| Seal fragments | Complete. Three cyan pickups in south-west Tideseal Ruins; COLLECT/E, saved IDs, no repeated pickup. | Existing collection untouched; explicit live HUD feedback and scroll counts. |
| Camps | Complete. Five active wolf IDs 0–4. Retired ID 5 remains represented in save compatibility. Optional Demon Boar is independent. | Placements, health, repeated attacks and rewards unchanged. |
| Western Watch | Partially correct in candidate. Scroll acceptance/reporting and 15-shard post-victory payment worked, but its fixed legacy coordinate search no longer matched relocated wolves. This could report completion prematurely. | Candidate binds to existing CampDemon0 and CampDemon1. Earlier kills count; unrelated wolves do not. Production legacy fallback retained. Existing reported saves are honored. |
| Cave / Keeper's Relics | Functional. Three proximity pickups; candidate moves relic ID 1 into the cave. All three plus chapter victory award 20 shards once. | Locations, collection radius, access and payment unchanged; explicit optional exploration guidance and deferred/paid state. |
| Moonleaf / grove | Functional. Eight ordinary plants and five grove plants each grant a potion. Three grove flowers grant 25 shards once, independently of chapter victory. | Existing logic reused; progress, potion benefit and independent reward explained. No new herbs or filler objectives. |
| Parchment quest scroll | Functional Q/button access, parchment, fonts, scroll, accept/complete/return controls. Objective text was scattered across several descriptions. | Same presentation and navigation. Current objective appears first; main/optional statuses and rewards share the existing authoritative fields. No mandatory NPC. |
| Completion / tracking | Counters and completion existed; HUD mostly showed the initial seal prompt. | Derived quest phases and five-second feedback in the existing panel; context hints for grove, cave relic and report-ready bounty. |
| Inventory / economy | Existing potions, shard balance, blade and armor upgrades. No general item-backpack architecture. Potion heal up to 50 health; upgrade levels 0–4. Optional boar pays 20, victory 80. | No inventory rewrite, item migration, balance or equipment changes. Rewards remain owned by campaign.gd. |
| Persistence | Complete v4 ConfigFile schema, atomic temporary/backup writes, v1–v3 migration, pickup IDs, cleared IDs, health/potions, equipment, waystones and reward flags. | Same schema and fields; new quest projection is not saved. Focused old-save and repeated reward tests added. |
| Existing boss / Dragon | Functional northern-lantern Tidewraith loop, boss states and victory/reload handling. | Preserved and regression-tested. This phase does not add boss development. |
| Future deep-cave story | Missing. Curved passage, chamber and reserved deeper hall exist, but no lantern illumination, discovery events, awakening sequence or final deep-cave encounter. | Dependency foundation only: chapter victory + all seals + cave relic. UI and diagram distinguish this future thread from the existing lantern/Tidewraith loop. No access lock or trigger added. |

## Primary existing implementation locations

`scripts/campaign.gd` owns progression, reward guards and saves; `campaign_store.gd` validates and migrates saves. `beach_seals.gd`, `shore_keeper.gd`, `relic_hunt.gd` and `herbal_plants.gd` own objectives. `premium_hud.gd` renders the existing quest panel. `island_candidate.gd` preserves candidate placement and binds Western Watch membership. `boss.gd`, `dragon_visual.gd` and the existing boar scripts remain unchanged.

## Remaining content limits

The journal adds connected reasons to visit existing places; it does not add new terrain, collectibles, NPCs, enemies, quest locations, equipment or scripted scenes. Mountain/grassland relics and the riverside herb route remain optional. Some full-map camp labels still use legacy regional symbols rather than five individual candidate wolf positions; this map overlay was not redesigned. Physical Samsung A37 integrated testing remains postponed.
