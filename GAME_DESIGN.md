# Veil of Veyra game design

**The Curse Awakens — Chapter I** follows Aru, an island warden investigating a curse that has left its mark across the coast and forest. The player reads the landscape, recovers three guardian fragments, restores the forest shrine and investigates Ancient Grove to find the source of the danger.

## Design pillars

- **Exploration and traces.** The Quest Journal and circular minimap support discovery. Shrines, tracks and damaged landmarks give the player clues in the world.
- **Readable melee combat.** The player reads wind-ups, dodges or guards, and counters through openings. The Demon Fox’s Phantom Veil and the Cursed Bear’s arena encounter give the guardians distinct combat rhythms.
- **Visible progression.** Earn Tide Shards through exploration and combat, buy standard gear and consumables in the Store, then manage the equipped loadout and upgrade gear in the Armory.
- **Scarce cosmetic rewards.** Eligible encounters and Chapter I completion grant Veil Gems once. Future appearance changes are intended to preserve combat stats and upgrade levels.
- **Android landscape first.** Touch movement, camera gestures, action buttons and persistent settings serve the mobile experience. Desktop bindings support development.

Chapter I is playable through the Lantern Awakening finale. See [release status](RELEASE_STATUS.md) for remaining work and [milestone records](docs/README.md#milestone-records) for earlier design iterations.

<details>
<summary>Historical notes from the original development snapshots</summary>

## Veil of Veyra

Created and developed by **Logachandran Hirukshanan**. See [project credits](docs/PROJECT_CREDITS.md) for game design, creative direction, soundtrack and asset provenance.

*Working title; the player name, title, and story details can change as we shape the game together.*

## Game idea

A third-person mobile demon-hunter RPG set on an original folklore-inspired island. Its old sea lanterns once kept tide demons beyond the reefs. When the western lantern goes dark, Aru, a new island warden, must hunt the demons reaching the shore and discover what is calling them inland.

## Feel and play

- Explore a small island area from behind the hero.
- Fight with a curved island blade and a short dodge.
- Learn the shore demons' attack rhythm, then face the Tidewraith Dragon.
- Earn Tide Shards to unlock new abilities through island quests.
- Keep the story and all names, characters, designs, music, and lore original.

## First playable slice

- One hero and one small shoreline clearing.
- Three simple tide demons followed by the Tidewraith Dragon boss.
- Movement, camera orbit, attack, dodge, health, and a clear objective.
- Keyboard/mouse controls for desktop development plus touch controls for phones.
- Simple placeholder shapes first; custom models, animation, voice, and a large world come later.

## Prototype success check

The player can move around the clearing, understand the controls, defeat the tide demons and boss, and reach a short victory message.



## Persistent island progression
The current game uses one continuous island: clear the camps, restore the northern lantern, defeat the dragon, then continue exploring. Quest actions and pickups persist across sessions. Optional herb gathering, relic recovery and Western Watch remain available after victory. New quests and characters can extend this world without chapter resets.


## Lantern seal quest
Recover three seal fragments at the south-west Tideseal Ruins and clear the three demon camps. Both objectives can be completed in either order. They unlock the northern lantern; lighting it reveals the Tidewraith. Each fragment is a persistent quest item collected with the contextual hand icon or E, with no potion cost or separate currency reward. Earlier saves with a lit lantern retain their progress automatically.

</details>
