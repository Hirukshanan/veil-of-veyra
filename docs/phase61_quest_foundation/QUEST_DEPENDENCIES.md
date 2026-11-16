# Chapter I quest dependencies

Solid links below are existing playable dependencies. Dashed links describe the future deep-cave story only. They are not triggers or new restrictions. The existing cave relic stays accessible before victory. Earlier objective completion counts even before bounty acceptance.

```mermaid
flowchart TD
    START[Explore Chapter I] --> SEAL[Collect 3 beach seal fragments]
    START --> CAMPS[Clear all 5 existing camp wolves]
    SEAL --> BOTH{Both complete}
    CAMPS --> BOTH
    BOTH --> LIGHT[Approach northern lantern and use LIGHT]
    LIGHT --> BOSS[Existing Tidewraith confrontation]
    BOSS --> VICTORY[Chapter victory: 80 shards once]
    START --> WATCH[Accept Western Watch in parchment scroll]
    WATCH --> PAIR[Clear western pair: CampDemon0 and CampDemon1]
    PAIR --> REPORT[Complete bounty in scroll]
    REPORT --> BOUNTY{Reported AND victory}
    VICTORY --> BOUNTY
    BOUNTY --> PAY15[15 shards once]
    START --> RELICS[3 relics: grassland, foothills, cave]
    RELICS --> RELICGATE{All relics AND victory}
    VICTORY --> RELICGATE
    RELICGATE --> PAY20[20 shards once]
    START --> HERBS[Moonleaf: one potion per plant]
    HERBS --> GROVE[3 grove flowers: 25 shards once]
    VICTORY -. future dependency only .-> FUTURE{Victory + 3 seals + cave relic}
    SEAL -.-> FUTURE
    RELICS -. cave relic only .-> FUTURE
    FUTURE -. not implemented .-> LANTERN[Future lantern-lit cave exploration]
    LANTERN -.-> DISCOVERY[Future ancient discoveries and Dragon presence]
    DISCOVERY -.-> AWAKEN[Future scripted awakening and encounter]
```

The future prerequisite view reads `completed`, `seal_fragments` and cave relic ID 1. It stores nothing and fires nothing. The reserved hall, future lantern item/lighting, ancient discovery events, awakening and final encounter remain outside Phase 6.1. The current northern lantern remains a world interaction, not a newly granted inventory lantern.
