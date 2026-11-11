# Project Guidelines & Change Operations

This document establishes the operational rules, patch management workflow, and quality gates for `project_chemical`. Every change—from minor bug fixes to major architectural overhauls—must follow this framework to maintain codebase stability, traceability, and high code quality.

---

## 1. Core Operating Principles

* **Logic-First Architecture (Headless / Decoupled):** Game mechanics, state, and chemical reaction engines must be completely decoupled from rendering and asset pipelines. Core rules must be 100% testable via CLI/unit tests without launching a graphics window or loading visual assets.
* **Reproducibility First:** All environments, dependencies, and outputs (especially scientific/chemical calculations) must be deterministic and reproducible.
* **Language & Communication Policy:**
  * **Code & Technical Documentation:** Written in **English** (source code, docstrings, comments, commit messages, PR descriptions, and markdown specifications) to maximize AI agent reasoning precision, token efficiency, and compatibility with global toolchains.
  * **Interactive Conversation & Planning:** Conducted in **Korean** for natural, fluid collaboration and requirement refinement with the user.
* **Atomic Changes:** Keep patches and PRs focused on a single responsibility. Avoid mixing refactoring, formatting, and feature additions in the same patch.
* **Document as You Go:** Code changes without accompanying documentation or test updates are considered incomplete.
* **Zero Broken Builds:** The `main` branch must remain in a releasable state at all times.

---

## 2. Branching & Lifecycle Strategy

We follow a modified Trunk-Based / Release-Branching workflow:

```
main (Production-ready / Tagged releases)
  │
  ├── hotfix/* (Emergency fixes for production releases)
  │
  └── feature/* | fix/* | refactor/* (Short-lived working branches)
```

### Branch Naming Conventions
* `feature/<short-desc>`: New functionality or domain capabilities (e.g., `feature/smiles-parser`).
* `fix/<short-desc>`: Bug fixes and routine patches (e.g., `fix/molecular-weight-rounding`).
* `hotfix/<version>`: Critical production fixes directly branched from and merged into `main` (e.g., `hotfix/0.1.1`).
* `refactor/<short-desc>`: Code structure improvements without functional changes.
* `docs/<short-desc>`: Documentation updates only.

---

## 3. Commit Message Standards

All commits must follow the **Conventional Commits** specification:

```
<type>(<scope>): <short description in imperative mood>

[optional body: explanation of why the change was made]

[optional footer: issue references, breaking change warnings]
```

### Types
* `feat`: A new feature or capability.
* `fix`: A patch/bug fix.
* `refactor`: Code restructurings that neither fix a bug nor add a feature.
* `perf`: Performance improvements.
* `test`: Adding or correcting tests.
* `docs`: Documentation updates.
* `chore`: Build scripts, CI/CD, dependency updates, maintenance.

### Breaking Changes
Indicate breaking changes with `!` before the colon or include `BREAKING CHANGE:` in the footer:
```
feat(api)!: change default output format of molecular descriptors to JSON
```

---

## 4. Patch & Change Management Workflow

Every change passes through five structured gates:

```
[1. Proposal / Issue] ➔ [2. Branch & Implement] ➔ [3. Quality Gates] ➔ [4. Review & Approval] ➔ [5. Release & Log]
```

### Gate 1: Proposal & Scope Definition
* Open an Issue or RFC for any substantial change or new feature.
* Define:
  * Problem statement / context.
  * Expected behavior and edge cases.
  * Potential impacts on existing chemical calculations or interfaces.

### Gate 2: Implementation & Isolation
* Branch from the latest `main`.
* Keep the diff minimal and scoped.
* Add unit/regression tests covering the new code and bug regression scenarios.

### Gate 3: Local Quality Gates (Automated Verification)
Before opening a pull request, the patch author must run:
1. **Linter / Formatter:** Verify code adheres to stylistic and static analysis rules.
2. **Unit & Regression Suite:** All tests must pass with zero failures.
3. **Type Safety:** Static type checking (e.g., `mypy`, `tsc`) must report zero errors.

### Gate 4: Code Review & Merging
* Open a Pull Request referencing the tracked Issue.
* At least one code review approval is required.
* PRs are squash-merged or rebased onto `main` to preserve a linear history.

### Gate 5: Release, Tagging & Rollback Strategy
* Update [CHANGELOG.md](file:///c:/Users/Hyun/Desktop/project_chemical/CHANGELOG.md).
* Tag release with Semantic Versioning (e.g., `v0.1.0`).
* **Rollback Plan:** Every patch must have an identifiable revert commit. If a patch introduces a regression in production, the release is immediately rolled back via `git revert <commit-hash>`.

---

## 5. Semantic Versioning (SemVer 2.0)

We follow strict `MAJOR.MINOR.PATCH` versioning:

* **MAJOR (`X.0.0`):** Incompatible API changes, breaking data schema changes, or breaking updates to core calculation algorithms.
* **MINOR (`0.X.0`):** Backwards-compatible additions, new modules, or significant performance enhancements.
* **PATCH (`0.0.X`):** Backwards-compatible bug fixes, security patches, and minor internal corrections.

---

## 6. Emergency Hotfix Protocol

When a critical bug or regression affects the active version:

1. **Create Branch:** Branch immediately from the tagged release commit on `main` as `hotfix/<patch-version>`.
2. **Minimal Patch:** Apply the smallest viable change that resolves the defect.
3. **Targeted Verification:** Run tests reproducing the bug and verifying the fix.
4. **Merge & Tag:** Merge back into `main` and tag the new patch release (e.g., `v0.1.1`).
5. **Update Changelog:** Add entry under `[Fixed]` in [CHANGELOG.md](file:///c:/Users/Hyun/Desktop/project_chemical/CHANGELOG.md).
6. **Post-Mortem:** Document root cause and preventative regression test cases in the original issue.
