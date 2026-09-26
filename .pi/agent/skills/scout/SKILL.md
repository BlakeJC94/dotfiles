---
name: scout
description: Scout a codebase and build or update a structured knowledge base at `.agents/knowledge`. Use when asked to explore, document, summarize, or build understanding of a project. Best for getting up to speed on unfamiliar codebases or auditing existing knowledge for staleness.
---

# Scout

Scout examines a codebase and creates a living knowledge base at `.agents/knowledge`. This is primarily agent-driven; the developer provides lightweight guidance and sign-off.

## Knowledge Base Structure

```
.agents/knowledge/
├── README.md                    # Top-level summary + checklist of suggested subtopics
├── architecture/                # (optional) High-level architecture docs
├── modules/<module-name>/       # Per-module deep dives
├── data-model/                  # Schema, types, database models
├── api/                         # API endpoints, contracts
├── workflows/                   # Business logic flows, state machines
├── dev-guide/                   # Dev environment, tooling, conventions
└── ...                          # Other logical groupings
```

## Workflow

### A. Knowledge Base Does Not Exist

1. **Scan the project** — Understand the top-level structure, language(s), framework(s), build system, key config files, entry points, and dependencies.

   ```bash
   ls -la
   # Explore further with find, tree, or targeted reads of key files
   ```

   > **Filter with `.gitignore`** — Use `git ls-files` or `rg --no-ignore` to scope your scan. Prefer `git ls-files` for a clean view of tracked files, or pipe `find` through `grep -Ff .gitignore` patterns when you need to see everything on disk while still respecting ignores.

2. **Create the knowledge directory**:

   ```bash
   mkdir -p .agents/knowledge
   ```

3. **Write top-level summary** — Write `.agents/knowledge/README.md` with:
   - Project name and one-sentence purpose
   - Language / runtime / framework
   - High-level architecture (2-3 paragraphs)
   - Key directories and their responsibilities
   - Build / test / run commands
   - External dependencies and services

4. **Identify subtopics** — From your scan, list logical modules, concepts, or areas that warrant deeper documentation. Append them to the top-level file as a task checklist:

   ```markdown
   ## Suggested Deep-Dives

   - [ ] **architecture/** — System architecture, component relationships, data flow
   - [ ] **modules/auth/** — Authentication and authorization
   - [ ] **modules/api/** — API endpoints and contracts
   - [ ] **data-model/** — Database schema, entities, migrations
   - [ ] **workflows/ci** — CI/CD pipeline and deployment
   ```

5. **Ask the developer** whether to proceed with any/all/none of the suggested deep-dives.

6. **For each approved topic**:
   - Create the subdirectory: `mkdir -p .agents/knowledge/<topic>`
   - Write a focused markdown file with `index.md` or `<topic>.md`
   - Update the checklist in `README.md` — mark it `[x]` when done
   - Present the summary and ask if corrections are needed before moving on

7. **Continue** until all approved items are documented or the developer calls it done.

### B. Knowledge Base Exists

1. **Check top-level summary is in sync** (highest priority):
   - Scan the project for changes: dependencies, entry points, directory structure, config files
   - Cross-reference against `.agents/knowledge/README.md`
   - Flag any outdated statements and propose corrections
   - Apply corrections after developer approval

2. **Identify stale or missing topics**:
   - For each subdirectory in `.agents/knowledge/`, check whether the described code/feature still exists and is still accurate
   - Check if new modules/features exist that aren't documented
   - Update checklist in README.md: mark stale items `[~]` and add new suggestions

3. **Present findings** to the developer and ask which updates to make.

## Conventions

- **Top-level file**: always `.agents/knowledge/README.md`
- **Subdirectory entry point**: `index.md` or `<topic>.md`
- **Checklist format**: `- [ ] task`, `- [x] done`, `- [~] stale/needs-update`, `- [-] skipped`
- Keep knowledge concise. Bullet points and brief sections > long prose.
- Link across files with relative paths where useful.
- When scanning, prefer `ls`, `find`, `rg`, and targeted `read` over exhaustive reads.
- **Respect `.gitignore`** — Use `git ls-files` to list tracked files, or pipe `rg` with `--no-ignore` to skip ignored paths. This avoids noise from `node_modules`, build artifacts, vendored code, and other generated content.

## Prompt Variations

| Developer says… | Action |
|---|---|
| *"Scout this codebase"* (no prompt) | Ask: "Shall I scan the project and build a high-level summary at `.agents/knowledge/`?" |
| *"Scout, focusing on the auth system"* | Only document the auth module. Skip the general summary step. |
| *"Scout, but skip the checklist"* | Build the top-level summary and stop; do not suggest deep-dives. |
| *"Update the knowledge base"* | Follow workflow B — check sync first, then stale topics. |