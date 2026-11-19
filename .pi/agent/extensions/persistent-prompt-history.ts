import { CustomEditor, SessionManager, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { UserMessage } from "@earendil-works/pi-ai";

type EditorArguments = ConstructorParameters<typeof CustomEditor>;

const MAX_PROMPTS = 100;

class PersistentHistoryEditor extends CustomEditor {
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
    if (this.editorKeybindings.matches(data, "tui.editor.historyPrevious")) {
      this.navigateHistory(-1);
      return;
    }
    if (this.editorKeybindings.matches(data, "tui.editor.historyNext")) {
      this.navigateHistory(1);
      return;
    }
    if (this.editorKeybindings.matches(data, "tui.editor.cursorDown") && this.promptHistoryIndex >= 0) {
      const cursor = this.getCursor();
      if (cursor.line === this.getLines().length - 1) {
        this.navigateHistory(1);
        return;
      }
    }
    if (this.editorKeybindings.matches(data, "tui.editor.cursorUp")) {
      const cursor = this.getCursor();
      if (this.getText().length === 0 || (cursor.line === 0 && cursor.col === 0)) {
        if (this.navigateHistory(-1)) return;
      }
    }

    const previousText = this.getText();
    super.handleInput(data);
    if (this.getText() !== previousText) {
      this.promptHistoryIndex = -1;
      this.promptHistoryDraft = undefined;
    }
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
    const prompts = await loadRecentPrompts(ctx.cwd);
    ctx.ui.setEditorComponent((tui, theme, keybindings) =>
      new PersistentHistoryEditor(tui, theme, keybindings, prompts),
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
