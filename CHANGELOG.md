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

### Changed
- Inventory capacity now applies only to raw elements; reaction compounds (e.g. `H2O`, `CH4`) are stored uncapped.

### Deprecated
- None

### Removed
- None

### Fixed
- Stored Energy / Output Power labels never updated due to incorrect node paths in `main.gd`.
- Reaction byproducts filling inventory capacity and permanently blocking manual mining.

### Security
- None
