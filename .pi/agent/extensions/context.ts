import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";

export default function (pi: ExtensionAPI) {
  let pendingContext: string | null = null;

  pi.registerCommand("context", {
    description: "Load the current PLAN file into context for the next turn. No-op if no PLAN exists.",
    handler: async (_args, ctx) => {
      try {
        const planPath = execSync("git plan", {
          encoding: "utf-8",
          cwd: ctx.cwd,
        }).trim();

        if (!existsSync(planPath)) {
          // Noop
          ctx.ui.notify("No PLAN file found", "info");
          return;
        }

        const content = readFileSync(planPath, "utf-8");
        pendingContext = content;
        ctx.ui.notify(
          `PLAN loaded (${content.length} chars). Will inject on next prompt.`,
          "info",
        );
      } catch {
        // Noop: not a git repo or no git plan alias
      }
    },
  });

  pi.on("before_agent_start", async (event, _ctx) => {
    if (!pendingContext) return;

    const content = pendingContext;
    pendingContext = null; // one-shot

    return {
      message: {
        customType: "plan-context",
        content: `Current PLAN:\n\n${content}`,
        display: false, // invisible to user in TUI
      },
    };
  });
}