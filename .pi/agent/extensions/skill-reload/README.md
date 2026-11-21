# Skill Reload Extension

After a context compaction, nudge the model to reload any skills whose instructions were summarized away — so a compacted session does not keep running on a skill it can no longer see.

## Files

- `index.ts` — Extension source

## Why

Skills are lazy-loaded: Pi keeps only each skill's name, description, and `SKILL.md` path in the system prompt, and the full instructions enter context only when the model reads the file (or you run `/skill:name`).

Compaction summarizes older messages into a short summary. If a skill was loaded earlier, its instructions are very likely gone — serialization even truncates tool results to 2000 characters. The system-prompt index survives, so the model still *knows the skill exists*, but it no longer knows the skill is *in use*. This extension supplies exactly that missing signal.

## What it does

When a compaction is about to start, the extension scans the messages being summarized for skill usage:

- a `<skill name="..." location="...">` block, produced by `/skill:name`
- a `read` tool call whose resolved path is a known skill's `SKILL.md` (including reads issued from `codemode` scripts)

If any skills were used, it appends one persisted, hidden custom message immediately after the compaction entry:

```text
<skill-reload-note>
This session was compacted. The following skills were in use before compaction, and
their detailed instructions may no longer be in your context. Re-read a skill's
SKILL.md with the read tool if the current task still depends on it:
- pdf-tools — /home/user/.agents/skills/pdf-tools/SKILL.md
</skill-reload-note>
```

The note is recorded on the branch, so it survives replay and is sent to the model as a user message. It is marked `display: false`, so it does not clutter the TUI. The model decides whether each skill is still relevant and re-reads it with the `read` tool.

## Behavior notes

- **No new turn.** The nudge is appended with `triggerTurn: false`; it rides along with the next request rather than starting its own.
- **Only summarized skills.** Detection runs against the span being summarized, so a skill whose body is still in the kept messages is not re-nudged.
- **Only on success.** Detection is stashed during `session_before_compact` and only persisted after `session_compact`; failures and cancellations (`session_compact_failed`) discard it.
- **Fresh skill list.** The known skills are refreshed on every `before_agent_start`, so `/reload` and project-local skills stay current.
- **No auto-reload.** Full skill bodies are deliberately not re-injected, to keep compaction's context savings. If the model ignores the nudge, that is the tradeoff.

## Events used

| Event | Purpose |
|-------|---------|
| `before_agent_start` | Cache the current skill list (`systemPromptOptions.skills`). |
| `session_before_compact` | Scan `preparation.messagesToSummarize` and `turnPrefixMessages` for used skills. |
| `session_compact` | Persist the nudge after a successful compaction. |
| `session_compact_failed` | Discard a pending nudge when compaction fails or is cancelled. |
