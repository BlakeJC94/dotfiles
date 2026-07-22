---
name: modern-python
description: Modern Python development with uv, ruff, and ty. Use when creating Python projects, adding dependencies, formatting, linting, type checking, or managing pyproject.toml. Enforces uv over pip/venv, ruff over black/isort/flake8, ty over mypy/pyright, and project.entry-points over scripts. Use ONLY for Python development tasks.
---

# Modern Python Development

All Python work uses the **uv** ecosystem. Never use pip, venv, virtualenv, pip-tools, poetry, pdm, or conda for any purpose. Never use black, isort, flake8, pylint, or mypy.

## Tool Chain

| Purpose | Tool | Command |
|---------|------|---------|
| Package/dependency manager | uv | `uv add`, `uv remove`, `uv sync`, `uv lock`, `uv run` |
| Formatter & linter | ruff | `ruff format`, `ruff check` |
| Type checker | ty | `ty check` |
| Python version manager | uv | `uv python install`, `uv python pin` |

## Dependency Management

### Adding dependencies

```bash
uv add <package>          # production dependency
uv add --dev <package>    # dev/test dependency
```

**Never** edit `pyproject.toml` `[project.dependencies]` or `[project.optional-dependencies]` by hand. Always use `uv add` / `uv remove` so `uv.lock` stays in sync.

### Removing dependencies

```bash
uv remove <package>
uv remove --dev <package>
```

### Syncing / installing

```bash
uv sync                   # install all deps from lockfile
uv sync --dev             # include dev dependencies
```

### Running commands in the project environment

```bash
uv run <command>          # e.g. uv run python -m myapp
uv run ruff check
uv run ty check
```

Never activate a venv manually. Always prefix with `uv run`.

## pyproject.toml

Every project must have a `pyproject.toml`. Use `uv init` to scaffold one if it does not exist.

### Required: entry points

Define CLI entry points under `[project.scripts]` and/or GUI entry points under `[project.gui-scripts]`:

```toml
[project.scripts]
mycli = "myapp.cli:main"

[project.gui-scripts]
mygui = "myapp.gui:main"
```

Do NOT use `[tool.setuptools.scripts]` or a top-level `scripts` table. Do NOT use `console_scripts` under `[tool.setuptools]`. The `[project.scripts]` table is the standard and works with every build backend uv supports.

### Required: build system

uv defaults to hatchling. This is fine. Do not change it unless the user explicitly asks.

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Project metadata

```toml
[project]
name = "my-app"
version = "0.1.0"
description = "..."
requires-python = ">=3.12"
dependencies = []                    # managed by uv add - do not hand-edit
```

Use `requires-python = ">=3.12"` for new projects unless the user specifies otherwise.

## Formatting & Linting

### Format

```bash
ruff format              # format all files
ruff format --check      # check without writing (CI)
```

### Lint

```bash
ruff check               # lint all files
ruff check --fix         # auto-fix
```

### Configuration

Place ruff config in `pyproject.toml`:

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]
```

Do NOT create standalone `ruff.toml` or `.ruff.toml` files. Keep it in `pyproject.toml`.

## Type Checking

```bash
ty check                 # type-check the project
```

Place ty config in `pyproject.toml`:

```toml
[tool.ty]
python-version = "3.12"

[tool.ty.environment]
extra-paths = ["."]
```

## Project Scaffolding

New project:

```bash
uv init my-app
cd my-app
uv add --dev ruff ty
```

This creates:
- `pyproject.toml` with hatchling build backend
- `src/my_app/__init__.py`
- `uv.lock`

After scaffolding, add entry points to `pyproject.toml` and add production dependencies with `uv add`.

## Verification Workflow

After any code change, run:

```bash
ruff format --check && ruff check && ty check
```

If formatting is wrong, run `ruff format` first, then re-check. If lint violations are auto-fixable, run `ruff check --fix`.

## Anti-Patterns to Flag

| Anti-pattern | Correct approach |
|-------------|-----------------|
| `pip install` | `uv add` for deps, `uv sync` to install from lock |
| `python -m venv` / `virtualenv` | uv manages venvs automatically |
| `requirements.txt` | `uv.lock` is the lockfile; do not hand-maintain requirements.txt |
| `poetry add` / `pdm add` | `uv add` |
| `black` / `isort` / `flake8` / `pylint` | `ruff format` + `ruff check` |
| `mypy` / `pyright` | `ty check` |
| `[tool.setuptools.scripts]` | `[project.scripts]` |
| `console_scripts` in setuptools | `[project.scripts]` |
| Hand-editing `[project.dependencies]` | `uv add` / `uv remove` |
| Missing `[project.scripts]` entry point | Add one for CLI apps |
| `python script.py` | `uv run python script.py` (or define an entry point) |
| `pip install -e .` | `uv sync` |

## Principles

- **uv for everything.** No exceptions. No pip, no poetry, no pdm, no conda.
- **Lockfile is truth.** `uv.lock` is the single source of truth for resolved dependencies. Never delete it, never hand-edit it.
- **Entry points are required.** Every installable package must declare `[project.scripts]` (or `[project.gui-scripts]`) so it is runnable after `uv sync`.
- **Format before lint before typecheck.** Fix ordering: `ruff format` -> `ruff check --fix` -> `ty check`.
