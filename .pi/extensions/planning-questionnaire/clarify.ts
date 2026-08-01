import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

import { messageText } from "./session.ts"
import { BLOCKED_DURING_CLARIFY } from "./types.ts"

/**
 * Register the `/clarify` command and its read-only planning guards.
 *
 * `/clarify` asks the agent to generate a batch of clarifying planning questions
 * via the `planning_questionnaire` tool. While that planning phase is active,
 * mutating tools (edit/write/bash) are blocked until the agent settles, at
 * which point the guard is lifted and the status indicator is cleared.
 */
export function registerClarifyCommand(pi: ExtensionAPI): void {
  let clarifyPlanningPhase = false

  // Block mutating tools while a clarify planning turn is in flight.
  pi.on("tool_call", async (event) => {
    if (!clarifyPlanningPhase) return
    if (!BLOCKED_DURING_CLARIFY.has(event.toolName)) return
    return {
      block: true,
      reason: `Blocked during clarify planning phase: ${event.toolName} is disabled until planning completes.`,
    }
  })

  // Clear the phase and status indicator once the agent finishes its turn.
  pi.on("agent_settled", async (_event, ctx) => {
    if (!clarifyPlanningPhase) return
    clarifyPlanningPhase = false
    ctx.ui.setStatus("clarify-mode", undefined)
  })

  pi.registerCommand("clarify", {
    description: "Ask context-aware clarifying planning questions",
    handler: async (_args, ctx) => {
      // /clarify rejects empty sessions to avoid blind questionnaire generation.
      const branch = ctx.sessionManager.getBranch()
      const recentUserContext = branch
        .slice()
        .reverse()
        .flatMap((entry) => {
          if (entry.type !== "message") return []
          const msg = entry.message as { role?: unknown }
          if (msg.role !== "user") return []
          const text = messageText(entry.message)
          if (!text) return []
          return [text]
        })
        .slice(0, 2)

      if (recentUserContext.length === 0) {
        ctx.ui.notify(
          "No user context found in this session. Ask something first, then run /clarify.",
          "warning",
        )
        return
      }

      if (!ctx.isIdle()) {
        ctx.ui.notify("/clarify can only run while the agent is idle.", "warning")
        return
      }

      const prompt = [
        "Call planning_questionnaire now.",
        "",
        "Based on the current session context, ask 3-6 clarifying planning questions that are needed before producing an implementation plan.",
        "",
        "Rules:",
        "- Questions must be concrete and decision-relevant",
        "- Prefer multiple choice options",
        "- Use multiple=true only when selection of several options is genuinely useful",
        "- Include custom=true when free-form input might be needed",
        "- Keep options concise",
        "",
        "After the questionnaire is answered, provide a short implementation plan.",
      ].join("\n")

      clarifyPlanningPhase = true
      ctx.ui.setStatus("clarify-mode", ctx.ui.theme.fg("warning", "clarify: read-only"))
      pi.sendUserMessage(prompt)
    },
  })
}
