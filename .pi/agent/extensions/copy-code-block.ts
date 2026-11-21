import {
  copyToClipboard,
  type ExtensionAPI,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import {
  decodeKittyPrintable,
  fuzzyFilter,
  Key,
  matchesKey,
  truncateToWidth,
  type Component,
  type TUI,
} from "@earendil-works/pi-tui";

/**
 * copy-code-block Pi extension
 *
 * Press <M-x> (alt+x) to open a picker of every fenced code block from the
 * assistant messages on the active branch, newest first. Filter by typing,
 * cycle with the arrow keys, watch the live preview, then Enter to copy the
 * highlighted block's contents (without the ``` fences) to the system
 * clipboard. <C-x> still copies the whole last message.
 *
 * Behavior:
 * - Collects code blocks from assistant messages on the active branch only,
 *   newest block first.
 * - The picker filters by language and the first lines of each block.
 * - Shows an error and copies nothing when there are no code blocks at all.
 */

const FENCE_OPEN_RE = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const FENCE_CLOSE_RE = /^ {0,3}(`{3,}|~{3,})[ \t]*$/;

const PREVIEW_LINES = 15;
const VISIBLE_ITEMS = 8;
const LANGUAGE_COLUMN = 14;

interface FencedBlock {
  /** Block contents without the surrounding fences. */
  code: string;
  /** First token of the fence info string, e.g. `ts`. Empty for a bare fence. */
  language: string;
}

/**
 * Return every fenced code block in `markdown`, in document order. Uses
 * CommonMark fence rules: a closing fence must use the same character and be
 * at least as long as the opening fence.
 */
function extractCodeBlocks(markdown: string): FencedBlock[] {
  const lines = markdown.split(/\r?\n/);
  const blocks: FencedBlock[] = [];
  let i = 0;

  while (i < lines.length) {
    const open = FENCE_OPEN_RE.exec(lines[i] ?? "");
    const info = open?.[2] ?? "";
    // Backtick fences cannot carry backticks in the info string (CommonMark).
    if (!open || (open[1][0] === "`" && info.includes("`"))) {
      i++;
      continue;
    }

    const fenceChar = open[1][0];
    const minLength = open[1].length;
    const body: string[] = [];
    let closed = false;
    let j = i + 1;

    for (; j < lines.length; j++) {
      const line = lines[j] ?? "";
      const close = FENCE_CLOSE_RE.exec(line);
      if (close && close[1][0] === fenceChar && close[1].length >= minLength) {
        closed = true;
        break;
      }
      body.push(line);
    }

    blocks.push({
      code: body.join("\n"),
      language: info.trim().split(/\s+/)[0] ?? "",
    });
    i = closed ? j + 1 : lines.length;
  }

  return blocks;
}

/** Text content of the most recent assistant message on the active branch. */
function assistantText(message: unknown): string | undefined {
  const m = message as { role?: unknown; content?: unknown } | undefined;
  if (m?.role !== "assistant" || !Array.isArray(m.content)) return undefined;

  const text = m.content
    .filter(
      (block): block is { type: "text"; text: string } =>
        typeof block === "object" &&
        block !== null &&
        (block as { type?: unknown }).type === "text" &&
        typeof (block as { text?: unknown }).text === "string",
    )
    .map((block) => block.text)
    .join("");

  return text.trim() ? text : undefined;
}

interface CodeBlock extends FencedBlock {
  /** 1-based position in the picker: 1 is the newest block. */
  index: number;
  /** Number of lines in the block. */
  lines: number;
  /** First non-empty line, trimmed, for the list row and filtering. */
  firstLine: string;
  /** Lowercased haystack used by the fuzzy filter. */
  matchText: string;
}

function toCodeBlock(block: FencedBlock, index: number): CodeBlock {
  const codeLines = block.code.split("\n");
  const nonEmpty = codeLines.map((line) => line.trim()).filter(Boolean);
  const firstLine = nonEmpty[0] ?? "(empty block)";
  const matchText = [block.language, ...nonEmpty.slice(0, 2)]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  return {
    ...block,
    index,
    lines: codeLines.length,
    firstLine,
    matchText,
  };
}

/** Collect code blocks from assistant messages, newest block first. */
function collectCodeBlocks(sessionManager: {
  getBranch(): readonly { type: string; message?: unknown }[];
}): CodeBlock[] {
  const branch = sessionManager.getBranch();
  const blocks: CodeBlock[] = [];

  for (let i = branch.length - 1; i >= 0; i--) {
    const entry = branch[i];
    if (!entry || entry.type !== "message") continue;

    const text = assistantText(entry.message);
    if (!text) continue;

    const found = extractCodeBlocks(text);
    for (let k = found.length - 1; k >= 0; k--) {
      const block = found[k];
      if (block) blocks.push(toCodeBlock(block, blocks.length + 1));
    }
  }

  return blocks;
}

/** Printable text typed into the filter, from Kitty or legacy input. */
function printableInput(data: string): string | undefined {
  const kitty = decodeKittyPrintable(data);
  if (kitty !== undefined) return kitty;
  // Legacy terminals send plain bytes. Escape sequences always contain ESC,
  // so exclude those (arrows, function keys, etc.) and control characters.
  if (data.length > 0 && !data.includes("\x1b") && /^[\x20-\x7e]+$/.test(data)) {
    return data;
  }
  return undefined;
}

/** Interactive code-block picker rendered inside `ctx.ui.custom()`. */
class CodeBlockPicker implements Component {
  private readonly tui: TUI;
  private readonly theme: Theme;
  private readonly blocks: CodeBlock[];
  private readonly done: (result: CodeBlock | null) => void;

  private filter = "";
  private selected = 0;
  private cached: string[] | undefined;

  constructor(
    tui: TUI,
    theme: Theme,
    blocks: CodeBlock[],
    done: (result: CodeBlock | null) => void,
  ) {
    this.tui = tui;
    this.theme = theme;
    this.blocks = blocks;
    this.done = done;
  }

  invalidate(): void {
    this.cached = undefined;
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
      if (this.filter) {
        this.filter = "";
        this.selected = 0;
        this.refresh();
        return;
      }
      this.done(null);
      return;
    }

    if (matchesKey(data, Key.enter)) {
      const chosen = this.list()[this.selected];
      if (chosen) this.done(chosen);
      return;
    }

    if (matchesKey(data, Key.up)) {
      this.move(-1);
      return;
    }
    if (matchesKey(data, Key.down)) {
      this.move(1);
      return;
    }
    if (matchesKey(data, Key.pageUp)) {
      this.move(-VISIBLE_ITEMS);
      return;
    }
    if (matchesKey(data, Key.pageDown)) {
      this.move(VISIBLE_ITEMS);
      return;
    }

    if (matchesKey(data, Key.backspace)) {
      if (this.filter) {
        this.filter = this.filter.slice(0, -1);
        this.selected = 0;
        this.refresh();
      }
      return;
    }

    const text = printableInput(data);
    if (text) {
      this.filter += text;
      this.selected = 0;
      this.refresh();
    }
  }

  render(width: number): string[] {
    if (this.cached) return this.cached;

    const w = Math.max(1, width);
    const rule = this.theme.fg("accent", "─".repeat(w));
    const list = this.list();
    const lines: string[] = [];

    lines.push(rule);

    const title = this.theme.bold(this.theme.fg("accent", "Copy code block"));
    const count = `${this.blocks.length} block${this.blocks.length === 1 ? "" : "s"} · Alt+X`;
    lines.push(truncateToWidth(` ${title}  ${this.theme.fg("muted", count)}`, w, "…"));

    const label = this.theme.fg("muted", "Filter: ");
    const value = this.filter
      ? this.theme.fg("text", this.filter)
      : this.theme.fg("dim", "type to filter by language or content");
    lines.push(truncateToWidth(` ${label}${value}`, w, "…"));

    lines.push(rule);

    if (list.length === 0) {
      lines.push(this.theme.fg("warning", " No matching code blocks"));
    } else {
      const { start, end } = this.visibleRange(list.length);
      for (let i = start; i < end; i++) {
        const block = list[i];
        if (block) lines.push(this.renderRow(block, i === this.selected, w));
      }
      if (start > 0 || end < list.length) {
        lines.push(this.theme.fg("dim", ` (${this.selected + 1}/${list.length})`));
      }
    }

    lines.push(rule);

    const selected = list[this.selected];
    if (selected) lines.push(...this.renderPreview(selected, w));
    else lines.push(this.theme.fg("dim", " No block selected"));

    lines.push(rule);
    lines.push(
      truncateToWidth(
        this.theme.fg("dim", " ↑/↓ move · type to filter · Enter copy · Esc clear/close"),
        w,
        "…",
      ),
    );
    lines.push(rule);

    this.cached = lines;
    return lines;
  }

  // ---- state ----

  /** Filtered blocks with the selection clamped into range. */
  private list(): CodeBlock[] {
    const query = this.filter.trim();
    const list = query ? fuzzyFilter(this.blocks, query, (b) => b.matchText) : this.blocks;
    if (this.selected >= list.length) this.selected = Math.max(0, list.length - 1);
    return list;
  }

  private move(delta: number): void {
    const length = this.list().length;
    if (length === 0) return;
    this.selected = (this.selected + delta + length) % length;
    this.refresh();
  }

  private refresh(): void {
    this.cached = undefined;
    this.tui.requestRender();
  }

  private visibleRange(length: number): { start: number; end: number } {
    const start = Math.max(
      0,
      Math.min(this.selected - Math.floor(VISIBLE_ITEMS / 2), length - VISIBLE_ITEMS),
    );
    return { start, end: Math.min(start + VISIBLE_ITEMS, length) };
  }

  // ---- rendering ----

  private renderRow(block: CodeBlock, active: boolean, width: number): string {
    const prefix = active ? "→ " : "  ";
    const num = `#${block.index}`.padEnd(4);
    const lang = (block.language || "text").slice(0, LANGUAGE_COLUMN).padEnd(LANGUAGE_COLUMN);
    const meta = `${block.lines}L`;

    const fixed = 2 + num.length + 1 + lang.length + 1 + meta.length + 2;
    const descWidth = Math.max(4, width - fixed);
    const desc = truncateToWidth(block.firstLine, descWidth, "…");

    const numColored = this.theme.fg(active ? "accent" : "muted", num);
    const langColored = this.theme.fg(active ? "accent" : "muted", lang);
    const descColored = this.theme.fg(active ? "text" : "muted", desc);
    const metaColored = this.theme.fg("dim", meta);

    return truncateToWidth(
      `${prefix}${numColored} ${langColored} ${descColored} ${metaColored}`,
      width,
      "…",
    );
  }

  private renderPreview(block: CodeBlock, width: number): string[] {
    const out: string[] = [];
    const header = `${block.language || "text"} · ${block.lines} line${
      block.lines === 1 ? "" : "s"
    }`;
    out.push(truncateToWidth(` ${this.theme.fg("muted", header)}`, width, "…"));

    const all = block.code.split("\n");
    const shown = all.slice(0, PREVIEW_LINES);
    const gutterWidth = String(shown.length).length;
    const textWidth = Math.max(1, width - gutterWidth - 3);

    for (let i = 0; i < shown.length; i++) {
      const gutter = String(i + 1).padStart(gutterWidth);
      const text = truncateToWidth(shown[i] ?? "", textWidth, "…");
      out.push(` ${this.theme.fg("dim", gutter)} ${text}`);
    }

    if (all.length > shown.length) {
      out.push(this.theme.fg("dim", `   … +${all.length - shown.length} more lines`));
    }

    return out;
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("alt+x", {
    description: "Pick a code block from recent agent messages and copy it",
    handler: async (ctx) => {
      const blocks = collectCodeBlocks(ctx.sessionManager);
      if (blocks.length === 0) {
        ctx.ui.notify("No code blocks in recent agent messages.", "error");
        return;
      }

      const chosen = await ctx.ui.custom<CodeBlock | null>(
        (tui, theme, _keybindings, done) =>
          new CodeBlockPicker(tui, theme, blocks, done),
      );
      if (!chosen) return;

      try {
        await copyToClipboard(chosen.code);
        ctx.ui.notify(`Copied code block #${chosen.index} to clipboard.`, "info");
      } catch (error) {
        ctx.ui.notify(
          error instanceof Error ? error.message : String(error),
          "error",
        );
      }
    },
  });
}
