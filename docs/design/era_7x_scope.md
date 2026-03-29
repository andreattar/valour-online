# Target era: classic 7.x feel (Valour Online)

## Perspective (corrected)

**Tibia** is presented as **oblique / top-down (~45°)**: the **logical** world is a **square tile grid** (north/south/east/west as a **plus**), not a 2:1 **diamond isometric** projection. Sprites and tiles are drawn to suggest depth; **movement and collision** stay on that **orthogonal** grid.

Valour uses a **square** `TileMapLayer` and **screen-aligned** `Vector2i` steps `(0,±1)`, `(±1,0)` — not diamond isometric math.

## Locked reference band

**Primary:** **7.4-style** pacing and systems — common reference for “classic” OT servers and player memory of early 2000s Tibia.

**Explicitly out of scope for v1 gameplay code:** **7.8+ stamina**, skinning/dusting minigames, and later loot-ownership rules. These can be revisited once core grid combat and hunting loop feel good.

## Systems mapping

| Concept | 7.x intent | Valour v1 implementation |
|--------|------------|---------------------------|
| Movement | One tile at a time, click + keyboard | Square grid `Vector2i`, smooth interpolation, BFS paths |
| Exhaust | Aggressive vs non-aggressive buckets | Two timers: `aggressive` (melee/spells), `utility` (reserved) |
| Hunting | Predictable spawns, overspawn pulls | Spawn points, per-area cap, respawn delay |
| Stamina | Fatigue for hunting (7.8+) | **Not implemented** until post-v1 |
| PvP | Skulls, zones | **Later** |

## Success check

Combat should read as **paced** (visible/exhaust-gated), not action-RPG spam. Movement should remain **tile-logical** even when visuals interpolate.
