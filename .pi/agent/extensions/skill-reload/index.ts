import { isAbsolute, normalize, resolve } from "node:path";
import type { ExtensionAPI, Skill } from "@earendil-works/pi-coding-agent";

/**
 * After a compaction, nudge the model to reload any skills whose instructions were
 * summarized away. The nudge is a persisted, hidden custom message appended right
 * after the compaction entry, so it survives on the branch until the next compaction.
 *
 * Skills reach the model one of two ways:
 * - `/skill:name` expands to a `<skill name="..." location="...">` user message.
 * - the model issues a `read` for a skill's `SKILL.md`.
 * Both are detected inside the messages that are about to be summarized.
 */

type ScanMessage = {
	role?: string;
	content?: unknown;
	nestedCalls?: { calls?: Array<{ name?: string; arguments?: Record<string, unknown> }> };
};

const SKILL_BLOCK_RE = /<skill\s+name="([^"]+)"\s+location="([^"]+)"/g;

function textOf(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.filter(
			(block): block is { type: string; text: string } =>
				typeof block === "object" &&
				block !== null &&
				(block as { type?: unknown }).type === "text" &&
				typeof (block as { text?: unknown }).text === "string",
		)
		.map((block) => block.text)
		.join("\n");
}

function readCalls(message: ScanMessage): Array<Record<string, unknown>> {
	const calls: Array<Record<string, unknown>> = [];
	if (message.role === "assistant" && Array.isArray(message.content)) {
		for (const block of message.content) {
			if (
				typeof block === "object" &&
				block !== null &&
				(block as { type?: unknown }).type === "toolCall" &&
				(block as { name?: unknown }).name === "read" &&
				typeof (block as { arguments?: unknown }).arguments === "object"
			) {
				calls.push((block as { arguments: Record<string, unknown> }).arguments);
			}
		}
	}
	for (const call of message.nestedCalls?.calls ?? []) {
		if (call.name === "read" && call.arguments) calls.push(call.arguments);
	}
	return calls;
}

/** Skills referenced by the summarized messages, as name -> SKILL.md path. */
function findUsedSkills(messages: ScanMessage[], skills: Skill[], cwd: string): Map<string, string> {
	const byPath = new Map(skills.map((skill): [string, Skill] => [normalize(skill.filePath), skill]));
	const found = new Map<string, string>();

	for (const message of messages) {
		if (message.role === "user" || message.role === "custom") {
			const text = textOf(message.content);
			if (text.includes("<skill")) {
				for (const match of text.matchAll(SKILL_BLOCK_RE)) found.set(match[1], match[2]);
			}
		}

		for (const args of readCalls(message)) {
			const raw = typeof args.path === "string" ? args.path : "";
			if (!raw) continue;
			const trimmed = raw.startsWith("@") ? raw.slice(1) : raw;
			const absolute = normalize(isAbsolute(trimmed) ? trimmed : resolve(cwd, trimmed));
			const skill = byPath.get(absolute);
			if (skill) found.set(skill.name, skill.filePath);
		}
	}

	return found;
}

function formatNudge(found: Map<string, string>): string {
	const lines = [
		"<skill-reload-note>",
		"This session was compacted. The following skills were in use before compaction, and",
		"their detailed instructions may no longer be in your context. Re-read a skill's",
		"SKILL.md with the read tool if the current task still depends on it:",
		...[...found].map(([name, location]) => `- ${name} — ${location}`),
		"</skill-reload-note>",
	];
	return lines.join("\n");
}

export default function skillReloadExtension(pi: ExtensionAPI): void {
	// Refreshed on every run so `/reload` and project-local skills stay current.
	let skills: Skill[] = [];
	let pending: Map<string, string> | undefined;

	pi.on("before_agent_start", (event) => {
		skills = event.systemPromptOptions.skills;
	});

	pi.on("session_before_compact", (event, ctx) => {
		const messages = [
			...event.preparation.messagesToSummarize,
			...event.preparation.turnPrefixMessages,
		] as unknown as ScanMessage[];
		const found = findUsedSkills(messages, skills, ctx.cwd);
		pending = found.size > 0 ? found : undefined;
	});

	pi.on("session_compact_failed", () => {
		pending = undefined;
	});

	pi.on("session_compact", () => {
		const found = pending;
		pending = undefined;
		if (!found || found.size === 0) return;
		pi.sendMessage(
			{
				customType: "skill-reload",
				content: formatNudge(found),
				display: false,
			},
			{ triggerTurn: false },
		);
	});
}
