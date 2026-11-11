# project_chemical

A chemical-themed 3D idle/production game built with **Godot Engine 4** using a **logic-first, headless-decoupled architecture**.

---

## Tech Stack & Engine

* **Engine:** Godot Engine 4.x
* **Core Language:** GDScript (Phase 1 pure logic scripts / Phase 2 scene scripting)
* **Architecture:** Decoupled Model-View / Headless Simulation Loop

---

## Roadmap & Milestones

* **Phase 1: Core Engine & Logic Framework (Current Focus)**
  * Implement headless game mechanics, state management, and chemical interaction rules (`src/core/`).
  * Resource gathering, element synthesis, reactor simulation, and automated tick updates.
  * Deterministic simulation loop and offline production calculation (`src/systems/`).
  * Automated testing and verification of all game formulas without visual dependencies.

* **Phase 2: 3D Visual Layer & Asset Integration**
  * 3D lab environment, reactor models, fluid pipes, and conveyor mechanics (`assets/3d/`).
  * Shaders for chemical fluids, bubbling particles, and reaction visual feedback.
  * HUD and UI controls connected to the core game state via signals.

---

## Project Structure

```
project_chemical/
├── project.godot               # Godot 4 project configuration
├── src/
│   ├── core/                   # Pure business logic (Chemicals, Reactors, Inventory, Upgrades)
│   ├── systems/                # Game state, Tick manager, Save/Load serialization
│   ├── scenes/                 # 2D/3D scenes (Main, HUD, Lab World)
│   └── tests/                  # Headless verification scripts
├── assets/                     # 3D models, textures, audio (Phase 2)
├── PROJECT_GUIDELINES.md       # Engineering & change management guidelines
├── CONTRIBUTING.md            # Contributor checklist
├── CHANGELOG.md               # Version & patch history
└── README.md                  # Project overview
```

---

## Documentation & Governance

* **[GAME_DESIGN.md](file:///c:/Users/Hyun/Desktop/project_chemical/GAME_DESIGN.md)**: Game concept, core loop, mechanics, and planetary exploration design.
* **[PROJECT_GUIDELINES.md](file:///c:/Users/Hyun/Desktop/project_chemical/PROJECT_GUIDELINES.md)**: Operating rules, branching strategy, commit conventions, patch approval gates, and hotfix protocols.
* **[CONTRIBUTING.md](file:///c:/Users/Hyun/Desktop/project_chemical/CONTRIBUTING.md)**: Developer workflow, local verification commands, and PR checklist.
* **[CHANGELOG.md](file:///c:/Users/Hyun/Desktop/project_chemical/CHANGELOG.md)**: History of version releases, patches, and fixes.

---

## Project Status

* **Status:** Phase 1 Complete (Stages 0–5 Verified, 58/58 Headless Tests Passing) — Ready for Phase 2 3D Asset Polish
* **Version:** 0.2.0-dev
