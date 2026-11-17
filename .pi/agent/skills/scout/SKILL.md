---
name: scout
description: Scout a codebase and create or refresh repository documentation skills under `.agents/skills/`. Use when asked to explore, document, summarize, or build understanding of a project, or to update repo-overview and component guides.
---

# Scout

Scout builds and maintains concise, source-verified repository skills under `.agents/skills/`. These skills are the durable, discoverable documentation for agents working in the repo; avoid creating a sporadic wiki.

## Skill Layout

```text
.agents/skills/
├── repo-overview/SKILL.md                 # Purpose and broad architecture
├── repo-component-<name>/SKILL.md         # Focused component guides, as needed
└── ...
```

Each skill uses YAML frontmatter with a short `name` and a `description` that makes its subject and trigger conditions clear. Write the body as practical repo context: explain current behavior and relationships, point to source paths, and avoid duplicating large sections of the README or source.

## Workflow

### Create or Refresh Repo Skills

1. **Inspect the current repo** — Read its local `AGENTS.md` and relevant `.agents/` instructions first. Scan tracked files, top-level structure, language/runtime, entry points, key configuration, dependencies, and available build/test commands. Use `git ls-files` when in a Git worktree; otherwise use targeted `find` and `rg` while avoiding generated or ignored content.
2. **Verify details in source** — Read the relevant implementation and configuration before documenting behavior. Treat existing documentation as a lead, not as proof; do not repeat stale claims.
3. **Create or refresh `repo-overview`** — Keep `.agents/skills/repo-overview/SKILL.md` focused on the repo's purpose, broad architecture, entry points, component relationships, and important conventions. Include source paths so agents can follow the explanation.
4. **Identify useful component guides** — Create `.agents/skills/repo-component-<name>/SKILL.md` for components with enough behavior, interactions, or domain rules to merit deeper context. Do not create a guide for every file or trivial module. Each guide should explain the component's responsibility, notable behavior and edge cases, dependencies/interactions, and authoritative source paths.
5. **Audit existing repo skills** — Compare each existing `repo-overview` and `repo-component-*` guide with the current implementation. Refresh outdated guides, add only useful missing component guides, and remove obsolete guides only when the component no longer exists. Keep unrelated skills untouched.
6. **Report** — Summarize created, updated, or removed skills and mention any areas that could not be verified. Do not ask for sign-off on routine documentation updates.

### Scoped Requests

- If the user requests one component, focus on that component guide and update the overview only when its broad architecture or component map is affected.
- If the user asks for an overview only, create or refresh `repo-overview` and skip component guides.
- If the user asks to update `.agents/knowledge/` specifically, follow that explicit format request rather than this default.

## Conventions

- Keep skills concise and grounded in the current source.
- Use exact repository-relative paths and avoid unverified API, command, or behavior claims.
- Prefer a small number of meaningful component guides over one guide per module.
- Do not create checklists for future deep-dives or approval gates; decide from the code which guides are useful.
- Respect `.gitignore` and avoid documenting generated files or vendored dependencies.
- Do not delete or migrate existing `.agents/knowledge/` content unless the user explicitly requests it.

## Prompt Variations

| Developer says... | Action |
|---|---|
| "Scout this codebase" | Scan the repo and create or refresh `repo-overview` plus useful component guides under `.agents/skills/`. |
| "Scout, focusing on the auth system" | Document the auth component; refresh the overview only if needed. |
| "Scout, overview only" | Create or refresh `repo-overview` and stop. |
| "Update the repo skills" | Audit and refresh existing `repo-overview` and `repo-component-*` guides against source. |
| "Update the knowledge base" | Ask whether they mean `.agents/knowledge/` or the default repo skills if context does not make that clear. |
