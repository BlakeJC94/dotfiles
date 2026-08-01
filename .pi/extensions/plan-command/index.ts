import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { isLikelyModifyingCommand, isPlanMdformatCommand, normalizePrompt } from "./utils.ts";

const PLAN_FILE = "PLAN.md";
const WRITE_TOOLS = new Set(["edit", "write"]);

export default function planCommandExtension(pi: ExtensionAPI): void {
	const planPath = resolve(process.cwd(), PLAN_FILE);
	let readOnlyResponsesRemaining = 0;
	let planWriteCallsRemaining = 0;
	let planFormatCallsRemaining = 0;

	function updateStatus(ctx: ExtensionContext): void {
		if (readOnlyResponsesRemaining > 0) {
			ctx.ui.setStatus("plan-command", ctx.ui.theme.fg("warning", "plan:read-only + PLAN.md write"));
			return;
		}
		ctx.ui.setStatus("plan-command", undefined);
	}

	pi.registerCommand("plan", {
		description: "Run one read-only planning response that updates PLAN.md",
		handler: async (args, ctx) => {
			const prompt = normalizePrompt(args);
			const planExists = existsSync(planPath);
			if (!prompt && !planExists) {
				ctx.ui.notify("Usage: /plan \"<prompt>\" when PLAN.md does not exist", "error");
				return;
			}

			const existingPlan = planExists ? readFileSync(planPath, "utf8") : "";

			readOnlyResponsesRemaining = 1;
			planWriteCallsRemaining = 1;
			planFormatCallsRemaining = 1;
			updateStatus(ctx);

			// AIDEV-NOTE: /plan allows one PLAN.md write/edit and one optional PLAN.md mdformat pass.
			const planningPrompt = [
				"Plan workflow mode is active for this response.",
				...(prompt ? [`Planning request: ${prompt}`] : []),
				"Update PLAN.md to reflect the requested implementation plan.",
				"If the scope is large, split work into non-overlapping streams that can be executed by multiple sub-agents.",
				"In PLAN.md, add a dedicated 'Parallel Streams' section so the developer can clearly see the parallelization strategy.",
				"When parallelizing is necessary, create one level-3 subsection (###) per sub-agent stream under that section.",
				"For each ### sub-agent section, define owner, boundaries, dependencies, and expected handoff artifacts.",
				"Create a checklist for the overall plan and a checklist inside each ### sub-agent section.",
				"Use Markdown task items (- [ ]) for all checklists.",
				"Each sub-agent section must also list other in-flight streams and shared touchpoints so agents stay constrained.",
				"You may make exactly one PLAN.md-modifying tool call via write or edit.",
				"After updating PLAN.md, try running 'mdformat PLAN.md' once via bash.",
				"If mdformat is unavailable or fails, continue without failing the plan update.",
				"Do not modify any other file.",
				"After updating PLAN.md, reply with a short confirmation only.",
				"Do not repeat the planning request in your response.",
				"",
				"Current PLAN.md content (if present):",
				existingPlan || "<missing>",
			].join("\n");

			if (ctx.isIdle()) {
				pi.sendUserMessage(planningPrompt);
				return;
			}

			pi.sendUserMessage(planningPrompt, { deliverAs: "followUp" });
		},
	});

	pi.on("before_agent_start", async () => {
		if (readOnlyResponsesRemaining <= 0) return;
		return {
			message: {
				customType: "plan-readonly-context",
				content: `[PLAN READ-ONLY MODE]\nAllow one write/edit call to PLAN.md and one optional 'mdformat PLAN.md' bash call. Block all other modifying actions.`,
				display: false,
			},
		};
	});

	pi.on("tool_call", async (event) => {
		if (readOnlyResponsesRemaining <= 0) return;

		if (WRITE_TOOLS.has(event.toolName)) {
			const rawPath = String(event.input.path ?? "").replace(/^@/, "");
			const targetPath = resolve(process.cwd(), rawPath);
			if (targetPath !== planPath) {
				return {
					block: true,
					reason: "Blocked by /plan mode: only PLAN.md may be modified.",
				};
			}
			if (planWriteCallsRemaining <= 0) {
				return {
					block: true,
					reason: "Blocked by /plan mode: the single allowed PLAN.md modification was already used.",
				};
			}
			planWriteCallsRemaining -= 1;
			return;
		}

		if (event.toolName === "bash") {
			const command = String(event.input.command ?? "");
			if (isPlanMdformatCommand(command)) {
				if (planFormatCallsRemaining <= 0) {
					return {
						block: true,
						reason: "Blocked by /plan mode: the optional PLAN.md mdformat call was already used.",
					};
				}
				planFormatCallsRemaining -= 1;
				return;
			}
			if (isLikelyModifyingCommand(command)) {
				return {
					block: true,
					reason: `Blocked modifying bash command in /plan mode: ${command}`,
				};
			}
		}
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (readOnlyResponsesRemaining > 0) {
			readOnlyResponsesRemaining -= 1;
			planWriteCallsRemaining = 0;
			planFormatCallsRemaining = 0;
			updateStatus(ctx);
		}
	});

	pi.on("session_start", async (_event, ctx) => {
		readOnlyResponsesRemaining = 0;
		planWriteCallsRemaining = 0;
		planFormatCallsRemaining = 0;
		updateStatus(ctx);
	});
}
