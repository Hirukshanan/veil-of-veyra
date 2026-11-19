# Chapter I · The Lantern's Seal

## Story and mystery

Aru arrives on Veyra to find out why the inland camps have gone quiet. At the shore, a dark stain runs up a ruin stone above the tide line. The same ash appears in the forest and on the animals attacking travelers. The island's old wards once contained something under the eastern mountain. Their failure gives the curse a path through the roots and waterways. Each main objective answers a question about that spread.

The Cursed Bear is Chapter I's major boss and the clearest example of what the curse does to living creatures. Tidewraith is the islanders' name for the single Charcoal Black Dragon. The chapter shows its crimson eye at a distance and leaves open whether it caused the curse or woke because the wards failed. The full Dragon fight belongs to the final chapter.

## First 15 minutes

The times are targets for a new player following the main objective. The player keeps control from the shoreline start, and exploration never runs on a timer.

| Time | Location and player action | What the player learns |
| --- | --- | --- |
| 0–2 min | **Beach camp.** On leaving camp, the player hears a warning bell cut short inland and sees the dark streak on a shore stone. Track **Follow the ash to Tideseal Ruins** in the existing HUD. The beach waystone is the first safe return point. | The danger has reached the route people use to leave the island. |
| 2–5 min | **Southwest Tideseal Ruins.** Follow the stain from the high-tide line to the broken seal. Use Pick/Interact on the first fragment. The stain stops at an intact carved line and continues through the break. | The seal was keeping something contained. The other two fragments are nearby, with their existing pickup IDs and positions. |
| 5–8 min | **Southwestern forest edge.** Follow the trail toward the nearest existing camp wolf. Use its crouch and lunge to teach a sword tap, a side dodge and a sword strike during recovery. Show one short cue at a time, tied to the wolf's tell or recovery. A missed dodge can be retried, and the route back to the beach stays open. | The wolf's darkened muzzle carries the same ash as the broken seal. The cure begins with finding where the ash travels. |
| 8–11 min | **Quiet camp edge.** Inspect the emberless fire and ash-blackened roots. A journal line records the finding: “The fire is cold. The roots are warm.” The dark roots run beneath the path toward the Northern Lantern. Allow this inspection on an approach that avoids the wolf. | The ash is spreading through the ground. The camp wolves are sick animals drawn to the warm roots around abandoned fires. |
| 11–15 min | **Woodland Trail junction.** Set **Restore the Northern Lantern** as the tracked objective. Players can finish the seal at the nearby ruins or scout the marked approach via Western Rise and return with a safe route in mind. Western Watch remains a voluntary detour. End the beat on the guidepost toward the dark lantern and the words “See where the roots lead.” | The lantern can reveal where the ash is entering the forest. The player chooses between securing the key and scouting the route. |

## Chapter I progression

1. **The Lantern's Seal — find the breach.** Reuse the three pickups, their locations and journal tracking. Give each shard a short finding about the same ward: its part at the shore, its connection to the northern lantern, and the route toward the mountain. The ruins tell one story through the three pieces.
2. **The Northern Lantern — trace the spread.** Light it with the repaired seal. Its light reveals the infected root line continuing northeast toward Ancient Grove. Remove the global five-wolf lock from the future candidate flow. Individual wolves still make their routes dangerous. Western Watch uses the existing western pair and keeps credit for earlier kills. Moonleaf Grove remains a preparation stop. The grassland and foothill relics add optional context about the ward network.
3. **Western Rise — confront or bypass the Demon Boar.** The boar guards a patch of the same infected roots on its existing forest route. It is an optional encounter on the way inland, available before the lantern is lit. Its charge lane, sweep and stomp reward the dodge-and-counter lesson, alongside the existing one-time 20-shard reward. The main trail remains usable through a safe bypass.
4. **Ancient Grove — break the Bear's hold.** The revived lantern leads Aru to the existing clearing. The Bear has wrapped itself around an infected root and each strike makes the ash pulse outward. Plan an encounter built around readable swipes, an outward shock and room to dodge and counter. Its defeat stops the local pulses and exposes a cave-ward mark. This is the chapter's major gameplay victory. Final encounter details belong to a later approved phase.
5. **Eastern cave — follow the warning beneath the mountain.** The existing cave relic identifies the inner altar. Reuse its pickup even when found early. With the whole seal, restored lantern, Bear victory and cave relic, Aru can place the lantern at the inner altar. The goal is to open the outer passage and find the source before the ward fails again.

## Climax and ending

Use the approved Lantern Awakening sequence as authored. Aru places the lantern, the pedestal descends, the wall breaks, and the distant roar gives way to the crimson eye. End Chapter I when the cinematic returns control, with the passage permanently open. Skip reaches the same saved ending. The Bear's defeat bought the island time, and the eye reveals how much remains below.

## Existing flow and next implementation steps

The candidate already tracks seal fragments, camps, relics, the optional Boar and journal objectives independently. Today, lighting the Northern Lantern requires all five camp wolves and three fragments, spawns Tidewraith, and uses its defeat for victory and deferred rewards. The cave cinematic then requires that victory, the lit lantern, the full seal and the cave relic. Those dependencies and their journal, map and field-guide copy need to change together.

1. After story approval, prototype only the candidate's opening route with the existing HUD, Interact, shore props and camp wolf. Add short clue text and check travel time, cue readability and the route past the Boar on desktop and touch.
2. Wire the northern lantern to the grove lead. Treat Bear victory as the eventual local victory and Awakening completion as the chapter ending. Retain the existing cinematic, cave geometry and reward values. Move the deferred bounty/relic payout gate to local victory, with the existing one-time protections.
3. Plan backward compatibility before changing quest gates. Keep prior fragment, relic, lantern, reward and passage progress. A previously opened passage counts as the finished chapter. A legacy Dragon victory without an opened passage preserves rewards and joins the new route at its next unmet objective. Keep the production scene available for rollback.
