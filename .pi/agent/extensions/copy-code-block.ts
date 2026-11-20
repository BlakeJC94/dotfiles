import { copyToClipboard, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * copy-code-block Pi extension
 *
 * Press <C-s> to copy the last fenced code block in the most recent agent
 * message to the system clipboard. <C-x> copies the whole last message; <C-s>
 * sits just above it and copies only the code, without the ``` fences.
 *
 * Behavior:
 * - Looks only at the last assistant message on the active branch.
 * - Copies the last fenced code block in that message (``` or ~~~).
 * - Shows an error and copies nothing when that message has no code block.
 */

const FENCE_OPEN_RE = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const FENCE_CLOSE_RE = /^ {0,3}(`{3,}|~{3,})[ \t]*$/;

/**
 * Return the contents of the last fenced code block in `markdown`, or null when
 * there is none. Uses CommonMark fence rules: a closing fence must use the same
 * character and be at least as long as the opening fence.
 */
function extractLastCodeBlock(markdown: string): string | null {
  const lines = markdown.split(/\r?\n/);
  let last: string | null = null;
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

    last = body.join("\n");
    i = closed ? j + 1 : lines.length;
  }

  return last;
}

/** Text content of the most recent assistant message on the active branch. */
function getLastAssistantText(
  sessionManager: {
    getBranch(): readonly { type: string; message?: unknown }[];
  },
): string | undefined {
  const branch = sessionManager.getBranch();

  for (let i = branch.length - 1; i >= 0; i--) {
    const entry = branch[i];
    if (!entry || entry.type !== "message") continue;

    const message = entry.message as
      | { role?: unknown; content?: unknown }
      | undefined;
    if (message?.role !== "assistant" || !Array.isArray(message.content)) {
      continue;
    }

    const text = message.content
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

  return undefined;
}

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("ctrl+s", {
    description: "Copy the last code block in the last agent message",
    handler: async (ctx) => {
      const text = getLastAssistantText(ctx.sessionManager);
      if (!text) {
        ctx.ui.notify("No agent message to copy from yet.", "error");
        return;
      }

      const code = extractLastCodeBlock(text);
      if (code === null || code.trim() === "") {
        ctx.ui.notify("No code block in the last agent message.", "error");
        return;
      }

      try {
        await copyToClipboard(code);
        ctx.ui.notify("Copied last code block to clipboard.", "info");
      } catch (error) {
        ctx.ui.notify(
          error instanceof Error ? error.message : String(error),
          "error",
        );
      }
    },
  });
}
