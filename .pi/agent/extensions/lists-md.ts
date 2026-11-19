import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";

/**
 * lists-md Pi extension
 *
 * Press <Shift+Enter> at the end of a Markdown list line to automatically
 * continue the list. Supports bullets, numbered lists, and checkboxes.
 *
 * - `- item` -> <Shift+Enter> -> `- `
 * - `* [ ] item` -> <Shift+Enter> -> `* [ ] `
 * - `1. item` -> <Shift+Enter> -> `2. `
 *
 * Indent list lines with <C-.> (indent right) / <C-,> (indent left) to match
 * the nvim lists-md plugin.
 *
 * Note: <C-.> and <C-,> require a terminal that reports enhanced key events
 * (Kitty keyboard protocol or modifyOtherKeys), because the raw control
 * characters for `.` and `,` collide with legacy terminal input.
 */

interface ParsedListLine {
  indent: string;
  marker: string;
  checkbox: string;
  content: string;
  isNumbered: boolean;
}

function parseListLine(line: string): ParsedListLine | null {
  const match = line.match(
    /^(\s*)((?:[-*+])|(?:\d+\.))(?:\[([ xX])\]\s*|\s+)(.*)$/
  );
  if (!match) return null;
  const [, indent, marker, checkbox = "", content] = match;
  const isNumbered = /^\d+\.$/.test(marker);
  return { indent, marker, checkbox, content, isNumbered };
}

function getContinuationPrefix(parsed: ParsedListLine): string {
  let marker = parsed.marker;
  if (parsed.isNumbered) {
    const num = parseInt(marker, 10);
    marker = `${num + 1}.`;
  }
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

// Emacs-style raw key sequences for the underlying editor.
const LINE_START = "\x01"; // ctrl+a
const DELETE_TO_LINE_END = "\x0b"; // ctrl+k
const INDENT_SIZE = 4;

class ListsMdEditor extends CustomEditor {
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
      super.handleInput(`\x1b[${-verticalDelta}A`); // move up
    } else if (verticalDelta > 0) {
      super.handleInput(`\x1b[${verticalDelta}B`); // move down
    }

    const targetLineText = this.getLines()[line] ?? "";
    const targetCol = Math.max(0, Math.min(col, targetLineText.length));
    if (targetCol > 0) {
      super.handleInput(`\x1b[${targetCol}C`); // move right
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

  handleInput(data: string): void {
    // Shift+Enter: continue list item.
    if (matchesKey(data, "shift+enter") && !this.isShowingAutocomplete()) {
      const { line, col } = this.getCursor();
      const lines = this.getLines();
      const currentLine = lines[line] ?? "";

      if (col !== currentLine.length) {
        super.handleInput(data);
        return;
      }

      const parsed = parseListLine(currentLine);
      if (parsed) {
        if (isEmptyListItem(parsed.content)) {
          // Empty list item: strip the marker and insert a plain newline.
          super.handleInput(LINE_START);
          super.handleInput(DELETE_TO_LINE_END);
          super.handleInput(data);
        } else {
          // Continue the list with a matching prefix.
          this.insertTextAtCursor(`\n${getContinuationPrefix(parsed)}`);
        }
        return;
      }
    }

    // C-. indent right — matches nvim lists-md indent_item_left (>>).
    if (matchesKey(data, "ctrl+.") && this.isOnListLine()) {
      this.modifyCurrentLine((line) => changeIndent(line, INDENT_SIZE), INDENT_SIZE);
      return;
    }

    // C-, indent left — matches nvim lists-md indent_item_right (<<).
    if (matchesKey(data, "ctrl+,") && this.isOnListLine()) {
      this.modifyCurrentLine((line) => changeIndent(line, -INDENT_SIZE), -INDENT_SIZE);
      return;
    }

    super.handleInput(data);
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;
    ctx.ui.setEditorComponent(
      (tui, theme, kb) => new ListsMdEditor(tui, theme, kb)
    );
  });
}
