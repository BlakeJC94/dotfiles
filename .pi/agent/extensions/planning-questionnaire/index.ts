import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

import { registerClarifyCommand } from "./clarify.ts"
import { registerQuestionnaireTool } from "./tool.ts"

/**
 * planning-questionnaire extension.
 *
 * Registers two things:
 *   1. The `planning_questionnaire` tool — an interactive batch questionnaire
 *      the agent calls to gather multiple clarifying answers in one widget.
 *   2. The `/clarify` command — drives a read-only planning phase that asks the
 *      agent to produce such a questionnaire from current session context,
 *      blocking mutating tools until the turn settles.
 */
export default function planningQuestionnaire(pi: ExtensionAPI): void {
  registerClarifyCommand(pi)
  registerQuestionnaireTool(pi)
}
