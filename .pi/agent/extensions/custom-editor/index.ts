import { CustomEditor, SessionManager, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";
import type { UserMessage } from "@earendil-works/pi-ai";

/**
 * custom-editor Pi extension
 *
 * A single input editor combines prompt snippets, Markdown-list editing, and
 * cross-session prompt history. Pi's `ctx.ui.setEditorComponent` is last-wins —
 * it replaces the editor instead of composing with it — so all editor behavior
 * lives here.
 *
 * Markdown lists:
 * - Press <Shift+Enter> at the end of a Markdown list line to continue it.
 *   - `- item`     -> <Shift+Enter> -> `- `
 *   - `* [ ] item` -> <Shift+Enter> -> `* [ ] `
 *   - `1. item`    -> <Shift+Enter> -> `2. `
 *   - `a. item`    -> <Shift+Enter> -> `b. `
 * - Indent with <C-.> (right) / <C-,> (left) to match the nvim lists-md plugin.
 *   Note: <C-.> and <C-,> require a terminal that reports enhanced key events
 *   (Kitty keyboard protocol or modifyOtherKeys), because the raw control
 *   characters for `.` and `,` collide with legacy terminal input.
 *
 * Prompt history:
 * - <Up> at the start of an empty input, or <Down> on the last line while
 *   browsing, cycles through prompts from recent sessions. This is separate
 *   from Pi's own in-session history.
 * - `tui.editor.historyPrevious` / `tui.editor.historyNext` are also honored
 *   when bound.
 */

type EditorArguments = ConstructorParameters<typeof CustomEditor>;

const MAX_PROMPTS = 100;
const INDENT_SIZE = 4;

const PROMPT_SNIPPETS: Record<string, string> = {
  review: [
    "Review the current change set: inspect git status, staged and unstaged diffs, and relevant untracked files.",
    "Focus on correctness, edge cases, and error handling. Do not modify files.",
    "Report only actionable findings as `file:line` - issue - impact. Omit empty categories; if none, say so.",
    "Additional focus (optional): ",
  ].join("\n"),
  debug: [
    "Investigate the symptom below. Do not edit files.",
    "Trace expected versus actual behavior. Check relevant code and environment/config before ranking causes.",
    "Report the most likely cause with evidence and one confirming check. If evidence is insufficient, say what is missing; do not guess.",
    "Symptom: ",
  ].join("\n"),
  test: [
    "Run the relevant project tests. Follow repository instructions and configuration; do not assume a package manager or default command.",
    "If I provide a command or suite below, run it; otherwise choose based on repository guidance.",
    "Report the command, pass/fail/skip counts, and failures as `file:line` - message. If all pass, give one line and stop.",
    "Command or suite (optional): ",
  ].join("\n"),
  explain: [
    "Explain the target below, or the current file/active symbol if blank.",
    "Use up to 5 short bullets: purpose, main flow, key design, and connections. Cite `file:line` for non-obvious claims.",
    "Target (optional): ",
  ].join("\n"),
  plan: [
    "Produce the smallest viable plan for the goal below. Inspect repository guidance and relevant code; do not edit.",
    "Return `file` - change - reason, then assumptions and verification commands. Stop at the plan.",
    "Goal: ",
  ].join("\n"),
  verify: [
    "Verify the claim below against the current code. Give a verdict: TRUE, FALSE, or PARTIAL.",
    "Cite exact `file:line` evidence. If not found, say NOT FOUND and list searched paths; do not speculate.",
    "Claim: ",
  ].join("\n"),
};

const PROMPT_SNIPPET_ALIASES: Record<string, keyof typeof PROMPT_SNIPPETS> = {
  ":r": "review",
  ":review": "review",
  ":d": "debug",
  ":debug": "debug",
  ":t": "test",
  ":test": "test",
  ":e": "explain",
  ":explain": "explain",
  ":p": "plan",
  ":plan": "plan",
  ":v": "verify",
  ":verify": "verify",
};

// Emacs-style raw key sequences for the underlying editor.
const LINE_START = "\x01"; // ctrl+a
const DELETE_TO_LINE_END = "\x0b"; // ctrl+k

interface ParsedListLine {
  indent: string;
  marker: string;
  checkbox: string;
  content: string;
}

function parseListLine(line: string): ParsedListLine | null {
  // Marker (bullet, numbered, or single letter), then whitespace, then an
  // optional checkbox (`[ ]` / `[x]`).
  const match = line.match(
    /^(\s*)((?:[-*+])|(?:\d+\.)|(?:[a-zA-Z]\.))\s+(?:\[([ xX])\]\s*)?(.*)$/
  );
  if (!match) return null;
  const [, indent, marker, checkbox = "", content] = match;
  return { indent, marker, checkbox, content };
}

/** Advance a numbered or lettered list marker to the next item. */
function nextMarker(marker: string): string {
  const num = marker.match(/^(\d+)\.$/);
  if (num) return `${parseInt(num[1]!, 10) + 1}.`;

  const alpha = marker.match(/^([a-zA-Z])\.$/);
  if (alpha) {
    const code = alpha[1]!.charCodeAt(0);
    // Wrap z -> a and Z -> A.
    const next = code === 90 ? 65 : code === 122 ? 97 : code + 1;
    return `${String.fromCharCode(next)}.`;
  }

  return marker;
}

function getContinuationPrefix(parsed: ParsedListLine): string {
  const marker = nextMarker(parsed.marker);
  const checkbox = parsed.checkbox ? `[${parsed.checkbox}] ` : "";
  return `${parsed.indent}${marker} ${checkbox}`;
}

function isEmptyListItem(content: string): boolean {
  return content.length === 0 || /^\s*$/.test(content);
}

function changeIndent(line: string, deltaSpaces: number): string {
  const currentIndent = line.match(/^(\s*)/)?.[1] ?? "";
  const rest = line.slice(currentIndent.length);
  if (deltaSpaces < 0) {
    const newIndent = currentIndent.slice(
      0,
      Math.max(0, currentIndent.length + deltaSpaces)
    );
    // Snap outdents to a multiple of INDENT_SIZE.
    const roundedIndent = newIndent.slice(
      0,
      newIndent.length - (newIndent.length % INDENT_SIZE)
    );
    return `${roundedIndent}${rest}`;
  }
  return `${" ".repeat(deltaSpaces)}${line}`;
}

class CustomEditorWithListsAndHistory extends CustomEditor {
  private readonly promptHistory: string[] = [];
  private promptHistoryIndex = -1;
  private promptHistoryDraft: string | undefined;
  private readonly editorKeybindings: EditorArguments[2];

  constructor(
    tui: EditorArguments[0],
    theme: EditorArguments[1],
    keybindings: EditorArguments[2],
    prompts: string[],
  ) {
    super(tui, theme, keybindings);
    this.editorKeybindings = keybindings;
    for (let i = prompts.length - 1; i >= 0; i--) {
      this.addToHistory(prompts[i]!);
    }
  }

  override addToHistory(text: string): void {
    const prompt = text.trim();
    if (!prompt) return;

    if (!this.promptHistory.includes(prompt)) {
      this.promptHistory.unshift(prompt);
      if (this.promptHistory.length > MAX_PROMPTS) this.promptHistory.pop();
    }
    super.addToHistory(prompt);
    this.promptHistoryIndex = -1;
    this.promptHistoryDraft = undefined;
  }

  override handleInput(data: string): void {
    if (this.handleHistoryNavigation(data)) return;

    const previousText = this.getText();
    if (!this.handlePromptSnippet(data) && !this.handleListInput(data)) {
      super.handleInput(data);
    }
    if (this.getText() !== previousText) {
      this.promptHistoryIndex = -1;
      this.promptHistoryDraft = undefined;
    }
  }

  /** Prompt-history keys. Returns true when the input was consumed. */
  private handleHistoryNavigation(data: string): boolean {
    if (this.editorKeybindings.matches(data, "tui.editor.historyPrevious")) {
      this.navigateHistory(-1);
      return true;
    }
    if (this.editorKeybindings.matches(data, "tui.editor.historyNext")) {
      this.navigateHistory(1);
      return true;
    }
    if (
      this.editorKeybindings.matches(data, "tui.editor.cursorDown") &&
      this.promptHistoryIndex >= 0
    ) {
      const cursor = this.getCursor();
      if (cursor.line === this.getLines().length - 1) {
        this.navigateHistory(1);
        return true;
      }
    }
    if (this.editorKeybindings.matches(data, "tui.editor.cursorUp")) {
      const cursor = this.getCursor();
      if (this.getText().length === 0 || (cursor.line === 0 && cursor.col === 0)) {
        if (this.navigateHistory(-1)) return true;
      }
    }
    return false;
  }

  /** Expand a prompt snippet when its token is followed by a space. */
  private handlePromptSnippet(data: string): boolean {
    if (data !== " ") return false;

    const text = this.getText();
    const lines = this.getLines();
    const { line, col } = this.getCursor();
    const offset =
      lines.slice(0, line).reduce((length, item) => length + item.length + 1, 0) + col;
    const match = text
      .slice(0, offset)
      .match(/(^|\s)(:r|:review|:d|:debug|:t|:test|:e|:explain|:p|:plan|:v|:verify)$/);
    if (!match) return false;

    const snippet = PROMPT_SNIPPETS[PROMPT_SNIPPET_ALIASES[match[2]!]!];
    const tokenStart = offset - match[0].length + match[1]!.length;
    const updated = text.slice(0, tokenStart) + snippet + text.slice(offset);
    this.setText(updated);

    const cursorLines = updated.slice(0, tokenStart + snippet.length).split("\n");
    this.moveCursorTo(cursorLines.length - 1, cursorLines[cursorLines.length - 1]!.length);
    return true;
  }

  /** Markdown-list keys. Returns true when the input was consumed. */
  private handleListInput(data: string): boolean {
    if (matchesKey(data, "shift+enter") && !this.isShowingAutocomplete()) {
      const { line, col } = this.getCursor();
      const lines = this.getLines();
      const currentLine = lines[line] ?? "";

      if (col !== currentLine.length) {
        // Not at end of line: fall through to the default newline behavior.
        return false;
      }

      const parsed = parseListLine(currentLine);
      if (!parsed) return false;

      if (isEmptyListItem(parsed.content)) {
        // Empty list item: strip the marker and insert a plain newline.
        super.handleInput(LINE_START);
        super.handleInput(DELETE_TO_LINE_END);
        super.handleInput(data);
      } else {
        // Continue the list with a matching prefix.
        this.insertTextAtCursor(`\n${getContinuationPrefix(parsed)}`);
      }
      return true;
    }

    // C-. indent right — matches nvim lists-md indent_item_left (>>).
    if (matchesKey(data, "ctrl+.") && this.isOnListLine()) {
      this.modifyCurrentLine((line) => changeIndent(line, INDENT_SIZE), INDENT_SIZE);
      return true;
    }

    // C-, indent left — matches nvim lists-md indent_item_right (<<).
    if (matchesKey(data, "ctrl+,") && this.isOnListLine()) {
      this.modifyCurrentLine((line) => changeIndent(line, -INDENT_SIZE), -INDENT_SIZE);
      return true;
    }

    return false;
  }

  private isOnListLine(): boolean {
    const { line } = this.getCursor();
    const lines = this.getLines();
    return parseListLine(lines[line] ?? "") !== null;
  }

  private moveCursorTo(line: number, col: number): void {
    const lastLine = this.getLines().length - 1;

    // After setText the cursor is at the end of the last line.
    // Jump to the start of the last line first.
    super.handleInput(LINE_START);

    const verticalDelta = line - lastLine;
    if (verticalDelta < 0) {
      for (let i = 0; i < -verticalDelta; i++) {
        super.handleInput("\x1b[A"); // move up
      }
    } else if (verticalDelta > 0) {
      for (let i = 0; i < verticalDelta; i++) {
        super.handleInput("\x1b[B"); // move down
      }
    }

    const targetLineText = this.getLines()[line] ?? "";
    const targetCol = Math.max(0, Math.min(col, targetLineText.length));
    for (let i = 0; i < targetCol; i++) {
      super.handleInput("\x1b[C"); // move right
    }
  }

  private modifyCurrentLine(
    fn: (line: string) => string,
    cursorDelta: number,
    options?: { gotoEnd?: boolean }
  ): void {
    const { line, col } = this.getCursor();
    const lines = this.getLines();
    const original = lines[line] ?? "";
    const updated = fn(original);

    if (updated === original) {
      return;
    }

    lines[line] = updated;
    this.setText(lines.join("\n"));

    const targetLine = Math.min(line, this.getLines().length - 1);
    const newLineLength = this.getLines()[targetLine]?.length ?? 0;
    const targetCol = options?.gotoEnd
      ? newLineLength
      : Math.max(0, Math.min(col + cursorDelta, newLineLength));
    this.moveCursorTo(targetLine, targetCol);
  }

  private navigateHistory(direction: -1 | 1): boolean {
    if (direction === -1) {
      const nextIndex = this.promptHistoryIndex + 1;
      if (nextIndex >= this.promptHistory.length) return this.promptHistory.length > 0;
      if (this.promptHistoryIndex === -1) this.promptHistoryDraft = this.getText();
      this.promptHistoryIndex = nextIndex;
      this.setText(this.promptHistory[nextIndex]!);
      return true;
    }

    if (this.promptHistoryIndex === -1) return false;
    if (this.promptHistoryIndex === 0) {
      const draft = this.promptHistoryDraft ?? "";
      this.promptHistoryIndex = -1;
      this.promptHistoryDraft = undefined;
      this.setTextAtStart(draft);
    } else {
      this.promptHistoryIndex--;
      this.setTextAtStart(this.promptHistory[this.promptHistoryIndex]!);
    }
    return true;
  }

  private setTextAtStart(text: string): void {
    this.setText(text);
    // setText places the cursor at the end; use editor keys to reach the first line.
    super.handleInput("\x1b[H");
    while (true) {
      const before = this.getCursor();
      if (before.line === 0 && before.col === 0) return;
      super.handleInput("\x1b[A");
      const after = this.getCursor();
      if (after.line === before.line && after.col === before.col) return;
    }
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    const prompts = await loadRecentPrompts(ctx.cwd);
    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) =>
        new CustomEditorWithListsAndHistory(tui, theme, keybindings, prompts)
    );
  });

  pi.registerShortcut("ctrl+shift+end", {
    description: "Move cursor to the end of the current input",
    handler: (ctx) => ctx.ui.setEditorText(ctx.ui.getEditorText()),
  });
}

async function loadRecentPrompts(cwd: string): Promise<string[]> {
  const sessions = await SessionManager.list(cwd);
  sessions.sort((a, b) => b.modified.getTime() - a.modified.getTime());

  const prompts: string[] = [];
  const seen = new Set<string>();
  for (const session of sessions) {
    let entries;
    try {
      entries = SessionManager.open(session.path).getEntries();
    } catch (error) {
      console.warn(`Prompt history: skipping unreadable session ${session.path}`, error);
      continue;
    }

    const sessionPrompts: string[] = [];
    for (const entry of entries) {
      if (entry.type !== "message" || entry.message.role !== "user") continue;
      const text = extractText(entry.message.content)?.trim();
      if (text) sessionPrompts.push(text);
    }

    for (let i = sessionPrompts.length - 1; i >= 0; i--) {
      const prompt = sessionPrompts[i]!;
      if (seen.has(prompt)) continue;
      seen.add(prompt);
      prompts.push(prompt);
      if (prompts.length >= MAX_PROMPTS) return prompts;
    }
  }
  return prompts;
}

function extractText(content: UserMessage["content"]): string | undefined {
  if (typeof content === "string") return content;
  const text = content.filter((item) => item.type === "text").map((item) => item.text).join("\n");
  return text || undefined;
}
