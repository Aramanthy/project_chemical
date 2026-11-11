# Game Design Document (GDD)

## 1. Executive Summary

* **Project Name:** Project Chemical (Working Title: *Planet Harvester: Element & Energy*)
* **Genre:** 3D Planetary Exploration + Chemical Synthesis + Energy Generation / Idle Automation
* **Engine:** Godot Engine 4.x (Forward+ / 3D)
* **Language Policy:** GDScript for implementation, English for code/docs, Korean for interactive design discussions.
* **Core Philosophy:** Logic-First Architecture (Phase 1 headless core mechanics $\rightarrow$ Phase 2 3D visual integration).

---

## 2. Core Vision: "Synthesize Elements, Generate Energy"

The player is an experimental chemist traversing a dormant alien planet. The fundamental driving force is **Energy ($J$ / Watts)**:

```
[1. Gather Light Elements] ➔ [2. Synthesize Heavier Elements] ➔ [3. Trigger High-Energy Reactions] ➔ [4. Produce Massive Watts (W/s)]
            ▲                                                                                                    │
            └──────────────────────── Reinvest Energy into Reactors & Planetary Grid ───────────────────────────┘
```

### Energy Scaling
* **Tier 1 (Chemical Combustion):** $H_2 + O \rightarrow H_2O$ + Small thermal energy ($kW$).
* **Tier 2 (Concentrated Synthesis):** Exothermic acid/fuel reactions ($MW$).
* **Tier 3 (Nuclear / Fusion):** $H \rightarrow He$, heavy fission elements ($GW$).
* **Tier 4 (Exotic Superheavies):** Fictional stable superheavy elements ("Island of Stability") releasing cosmic power ($TW$).

---

## 3. Planetary Exploration Hook

* **Camera:** Third-person over-the-shoulder view (Astroneer / Palworld style). The camera follows behind the player character, emphasizing horizon views and 3D spatial exploration.
The planet contains dormant alien power stations, containment towers, and energy conduits.
* The player explores the planet to discover raw catalyst vents and dormant reactors.
* By synthesizing and injecting the required elemental mixtures, reactors come online, expanding the global power grid.
* The ultimate milestone is fully powering the planet's Central Core.

---

## 4. System Architecture (Phase 1 Focus)

All core simulation logic is headless and completely independent of Godot rendering nodes:

```
src/
├── core/
│   ├── element_data.gd        # Elements, compounds, atomic mass, reaction energy (Joules/mol)
│   ├── energy_system.gd       # Total stored energy, real-time power rate (W/s), peak production
│   ├── reaction_chamber.gd    # Consumes elements, triggers reactions, outputs energy + byproducts
│   ├── player_inventory.gd    # Carried elements, capacity (raw elements only)
│   ├── machine.gd             # Base class for deployable machines + status model   [Stage 1 ✅]
│   ├── auto_extractor.gd      # Continuous element extraction with power draw       [Stage 1 ✅]
│   ├── reactor_machine.gd     # Repeating recipe reactor feeding the energy grid    [Stage 1 ✅]
│   └── machine_catalog.gd     # Machine definitions, build costs, factory           [Stage 1 ✅]
├── systems/
│   ├── game_state.gd          # Aggregate root: energy, storage, machines           [Stage 1 ✅]
│   ├── simulation_loop.gd     # Deterministic fixed-timestep (0.1s) driver          [Stage 1 ✅]
│   ├── planet_grid.gd         # Coordinate-based planetary resource nodes & dormant power hubs
│   ├── tech_tree.gd           # Energy-based upgrades, capacity expansions, recipe unlocks [Stage 2 ✅]
│   └── save_system.gd         # JSON state persistence and offline energy calculation
├── scenes/
│   └── main.tscn              # Testing harness and headless visualizer
└── tests/                     # Headless unit + scene integration tests
```


---

## 4. Phase 2 Visual Integration (Preview)

* 3D low-poly or stylized planetary terrain with atmospheric scattering.
* Animated deployable buildings (rotating drills, bubbling liquid chambers, glowing heat exhausts).
* Overhead HUD showing resource flow rates, inventory meters, and pinned crafting recipes.
