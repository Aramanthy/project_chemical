# Contributing to project_chemical

Thank you for contributing! To maintain consistency and software stability, please adhere to this guide when proposing or making changes.

---

## Getting Started

1. **Clone & Setup:**
   * Ensure your local environment matches the project's dependency requirements.
   * Install dependencies in an isolated virtual environment or package container.

2. **Branching:**
   * Always pull the latest changes from `main`:
     ```bash
     git checkout main
     git pull origin main
     ```
   * Create a descriptive branch according to [PROJECT_GUIDELINES.md](file:///c:/Users/Hyun/Desktop/project_chemical/PROJECT_GUIDELINES.md#branch-naming-conventions):
     ```bash
     git checkout -b feature/your-feature-name
     # or
     git checkout -b fix/issue-description
     ```

---

## Development & Code Standards

* **Atomic Commits:** Make small, logical commits adhering to [Conventional Commits](https://www.conventionalcommits.org/):
  ```bash
  git commit -m "fix(parser): handle empty smiles string without throwing exception"
  ```
* **Testing:**
  * Add unit tests for every new function, class, or endpoint.
  * For bug fixes, include a regression test that fails before your patch and passes after it.
  * Tests live in `src/tests/test_*.gd`, extend `TestCase`, and use `test_*` method names.
  * Run the full headless suite before every commit:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\tools\run_tests.ps1
    ```
    Set `$env:GODOT_BIN` if Godot is not at `%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe`.
* **Documentation:**
  * Update inline docstrings for modified APIs.
  * Update top-level documentation (e.g., `README.md`, specs) if behavior or parameters change.

---

## Pull Request Checklist

Before opening or requesting review on a Pull Request, confirm the following:

- [ ] Branch is rebased onto the latest `main`.
- [ ] Code adheres to project formatting and linting rules.
- [ ] Type checks pass without warnings or errors.
- [ ] All existing and new tests pass locally.
- [ ] Commit messages follow Conventional Commits format.
- [ ] [CHANGELOG.md](file:///c:/Users/Hyun/Desktop/project_chemical/CHANGELOG.md) updated under `[Unreleased]` if applicable.
- [ ] Revert/rollback plan is identified in case of unexpected regressions.
