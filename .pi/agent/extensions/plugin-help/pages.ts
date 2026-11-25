export const pages: Record<string, string> = {
  "agents-cron": `agents-cron
Schedule one-off reminders, recurring jobs, and cron tasks that run in isolated agent sessions.
Use: Ask Pi in plain language, or use /remind, /loop, or /schedule. Browse tasks with /schedule list; use /schedule help for the available actions.`,
  btw: `btw
Ask the model a private side question without adding it to the main conversation history.
Use: /btw <question>; use /btw-add to import the aside into the session, /btw-history to count prior turns, /btw-clear to discard it, and /btw-close to hide it.`,
  "commands": `/commands
Browse registered slash commands grouped by extensions, prompts, and skills.
Use: /commands, or filter with /commands extension, /commands prompt, or /commands skill.`,
  "contextual-agents": `contextual-agents
Automatically adds relevant nested AGENTS.md or CLAUDE.md instructions when Pi reads or edits files in a Git repository.
Use: Add those context files beside the code they govern; the extension discovers and injects them automatically.`,
  "copy-code-block": `copy-code-block
Pick and copy a fenced code block or Markdown quote from recent assistant messages.
Use: Press Alt+X, filter by type, language, or text, then press Enter to copy without the outer fence or quote markers.`,
  "custom-editor": `custom-editor
Adds prompt snippets, Markdown-list editing, and prompt history to Pi's editor.
Use: Type :r, :d, :t, :e, :p, or :v followed by a space for a prompt template. Ctrl+; adds or removes a * list marker; Shift+Enter continues a list; Ctrl+. and Ctrl+, indent or outdent. Up/Down browse prompt history when the input is empty.`,
  "herdr-agent-state": `herdr-agent-state
Reports Pi's idle, working, and blocked state to the parent Herdr pane.
Use: It runs automatically in a Herdr-managed Pi session when HERDR_ENV=1, HERDR_SOCKET_PATH, and HERDR_PANE_ID are set.`,
  "hidden-thinking-label": `hidden-thinking-label
Changes the label shown for collapsed reasoning blocks.
Use: /thinking-label <text> sets a custom label; /thinking-label resets it. Ctrl+T toggles reasoning visibility.`,
  "mono-skills": `mono-skills
Discovers and prefixes skills from nested .agents/skills directories in a monorepo, and catalogs nested agent docs.
Use: /refreshskills after changing nested skills; /clearskills removes the repo cache. Call agents_dirs(path) to find applicable AGENTS.md and .agents directories.`,
  "my-agent": `my-agent
Selects planner, coder, reviewer, or monkey roles, and can summon fresh role agents through Herdr.
Use: /agent planner|coder|reviewer|monkey. Summon with /agent summon-tab, /agent summon-workspace, or /agent summon-pane. Requires HERDR_ENV=1 and Herdr pane context.`,
  nextbit: `nextbit
Adds the Nextbit model provider to Pi's model picker.
Use: /login nextbit to authenticate, then choose a Nextbit model with /model.`,
  "nvim-editor-improved": `nvim-editor-improved
Opens the prompt in nvim with a read-only conversation snapshot above it.
Use: /vim or Alt+G. Save and quit with :wq to submit; use :PiEdit to return text to Pi without submitting, or :cq to cancel.`,
  "pi-declutter": `pi-declutter
Groups each assistant response into a compact activity card, with details available on demand.
Use: Click a card or press Ctrl+O to expand or collapse all; open a row for full output, and press c to copy its text.`,
  "pi-file-snapshots": `pi-file-snapshots
Keeps file checkpoints before Pi write/edit operations so you can restore the working tree to an earlier conversation point.
Use: /snapshots to choose a checkpoint and restore it; /fork offers to restore files to the fork point. Bash changes are not captured.`,
  "pi-hermes-memory": `pi-hermes-memory
Provides durable memory, conversation search, reusable skills, and secret scanning across Pi sessions.
Use: Ask Pi to use memory_add or memory_search; use session_search for past conversations and skill_manage to manage procedures. /memory-index-sessions indexes older sessions; /learn-memory-tool explains the memory tools.`,
  "pi-lsp-extension": `pi-lsp-extension
Provides language-server intelligence and syntax-aware code search/refactoring tools.
Use: Call lsp_diagnostics, lsp_hover, lsp_definition, lsp_references, lsp_symbols, lsp_rename, lsp_code_actions, or lsp_completions. /lsp shows server status; /lsp-config configures a server.`,
  "planning-questionnaire": `/clarify
Collects planning questions in one interactive batch and offers a read-only planning command.
Use: Run /clarify to start the questionnaire; the planning tool can gather multiple decisions before drafting a plan.`,
  "plugin-help": `/plugin-help
Lists extensions found in the local Pi extension directories and packages reported by pi list. Shows the locally maintained TL;DR for a selected extension.
Use: /plugin-help to browse names; /plugin-help <name> to show its page.`,
  "prompt-injection-guard": `prompt-injection-guard
Scans tool inputs and outputs for prompt-injection patterns and applies the configured handling mode.
Use: /injection-guard to inspect settings, /injection-guard mode <mode> to change behavior, or /injection-guard test <text> to check a sample.`,
  "skill-reload": `skill-reload
After compaction, reminds Pi which skills were used so their instructions can be reloaded if still relevant.
Use: Automatic. If a reminder appears, reread the named SKILL.md files for the current task.`,
  tips: `tips
Keeps an active-snippets reminder above the editor while Pi is ready for input. Adds a rotating tip at session start and every 6–10 completed turns.
Use: Automatic. Edit the pi-tips block in the extensions README to change the rotating tips.`,
  "web-search": `web-search
Adds DuckDuckGo search and page-fetching tools, plus a quick search command.
Use: /websearch <query>, or call web_search, web_fetch, and web_research for structured search and page extraction.`,
  "@wileai/pi-codex-connector": `@wileai/pi-codex-connector
Uses your connected Codex apps and direct web search from any Pi model.
Use: /codex-connectors to browse; use codex_connectors, codex_connector_schema, and codex_connector_call for connected apps. /codex-web-search sets search access. Requires Codex login and the relevant data permission.`,
};
