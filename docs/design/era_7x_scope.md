# Target era: classic 7.x feel (Valour Online)

## Locked reference band

**Primary:** **7.4-style** pacing and systems — common reference for “classic” OT servers and player memory of early 2000s Tibia.

**Explicitly out of scope for v1 gameplay code:** **7.8+ stamina**, skinning/dusting minigames, and later loot-ownership rules. These can be revisited once core grid combat and hunting loop feel good.

## Systems mapping

| Concept | 7.x intent | Valour v1 implementation |
|--------|------------|---------------------------|
| Movement | One tile at a time, click + keyboard | Grid `Vector2i`, smooth interpolation, BFS paths |
| Exhaust | Aggressive vs non-aggressive buckets | Two timers: `aggressive` (melee/spells), `utility` (reserved) |
| Hunting | Predictable spawns, overspawn pulls | Spawn points, per-area cap, respawn delay |
| Stamina | Fatigue for hunting (7.8+) | **Not implemented** until post-v1 |
| PvP | Skulls, zones | **Later** |

## Success check

Combat should read as **paced** (visible/exhaust-gated), not action-RPG spam. Movement should remain **tile-logical** even when visuals interpolate.
