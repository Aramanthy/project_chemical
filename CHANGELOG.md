# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial project governance and operating guidelines ([PROJECT_GUIDELINES.md](file:///c:/Users/Hyun/Desktop/project_chemical/PROJECT_GUIDELINES.md)).
- Contribution guidelines and developer checklist ([CONTRIBUTING.md](file:///c:/Users/Hyun/Desktop/project_chemical/CONTRIBUTING.md)).
- Changelog tracking system ([CHANGELOG.md](file:///c:/Users/Hyun/Desktop/project_chemical/CHANGELOG.md)).
- Bilingual policy (English for code/docs, Korean for interactive conversation) in [PROJECT_GUIDELINES.md](file:///c:/Users/Hyun/Desktop/project_chemical/PROJECT_GUIDELINES.md).
- Selected **Godot Engine 4** (GDScript) as primary platform with 2-phase headless roadmap in [README.md](file:///c:/Users/Hyun/Desktop/project_chemical/README.md).
- Comprehensive Game Design Document ([GAME_DESIGN.md](file:///c:/Users/Hyun/Desktop/project_chemical/GAME_DESIGN.md)) defining "Element Synthesis & Energy Generation" core loop and planetary exploration progression.
- Phase 1 Core Modules:
  - `src/core/element_data.gd`: Element tiers, properties, and reaction recipes.
  - `src/core/energy_system.gd`: Stored Joules, power rate (W), and engineering unit formatters.
  - `src/core/player_inventory.gd`: Elemental ledger with atomic add/consume operations and limits.
  - `src/core/reaction_chamber.gd`: Synthesis reactor loop converting elements into energy and outputs.
- Phase 1 Test Harness:
  - `src/scenes/main.tscn` & `src/scenes/main.gd`: Interactive simulator demonstrating real-time mining, reaction progress, energy generation, and log stream.
- Headless test framework (`src/tests/`) with 19 unit tests covering energy, inventory, and reaction chamber logic.
- Test runner script `tools/run_tests.ps1` (detects parse errors and failures; exits non-zero on failure).
- **Stage 1 — Automation Core:**
  - `Machine` base class with status reporting (Running / No Power / No Input / Storage Full / Disabled).
  - `AutoExtractor` (continuous element extraction with power draw) and `ReactorMachine` (repeating recipe reactor).
  - `MachineCatalog` data definitions and factory (H/O/C extractors, water/methane reactors).
  - `GameState` aggregate root (energy, storage, machines, build costs).
  - `SimulationLoop` deterministic fixed-timestep (0.1s) driver, frame-rate independent.
  - Automation column in the test scene: build buttons and live machine status list.
- Scene integration test that instantiates `main.tscn` and drives it through UI handlers.
- Test runner now attributes runtime script errors to the failing test (custom `Logger`).
- **Stage 2 — Progression & Tech Tree:**
  - `TechTree` (`src/systems/tech_tree.gd`) with repeatable scaling upgrades (`mining_laser`, `storage_expansion`, `extractor_overclock`, `reactor_catalysts`) and tier gates (`unlock_tier_3_nuclear`, `unlock_tier_4_exotic`).
  - Expanded `MachineCatalog` with Tier 3 Nuclear (`extractor_u`, `reactor_fusion`, `reactor_fission`) and Tier 4 Exotic (`extractor_ex119`, `reactor_astral`) machines.
  - Automatic propagation of tech multipliers to inventory capacity, existing/newly deployed machines, and handheld reactions in `GameState`.
  - Tech Tree & Upgrades UI column in `main.tscn` / `main.gd` + 7 new unit tests in `test_tech_tree.gd` (45 tests total).
- **Stage 3 — Persistence & Offline Progress:**
  - `SaveSystem` (`src/systems/save_system.gd`) providing JSON state serialization (`to_dict` / `from_dict`), file persistence (`user://savegame.json`), and bounded deterministic offline progress calculation (up to 24h cap).
  - Save / Load / Simulate +60s Offline controls in `main.tscn` / `main.gd` + 4 new tests in `test_save_system.gd` (49 tests total).

### Changed
- Inventory capacity now applies only to raw elements; reaction compounds (e.g. `H2O`, `CH4`) are stored uncapped.

### Deprecated
- None

### Removed
- None

### Fixed
- Stored Energy / Output Power labels never updated due to incorrect node paths in `main.gd`.
- Reaction byproducts filling inventory capacity and permanently blocking manual mining.
- Float drift (10 x 0.1s = 0.9999999s) made 1s reactions take 1.1s and delayed power readings; excess time now carries over between auto-repeated reactions.

### Security
- None
