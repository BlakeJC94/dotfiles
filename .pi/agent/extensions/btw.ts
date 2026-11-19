import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AssistantMessage, TextContent, UserMessage } from "@earendil-works/pi-ai";
import { Text } from "@earendil-works/pi-tui";

type BtwTurn = {
	user: UserMessage;
	assistant: AssistantMessage;
	userText: string;
	assistantText: string;
};

export default function btwExtension(pi: ExtensionAPI) {
	// In-memory side-channel history. Lost on /reload or Pi restart, by design.
	let history: BtwTurn[] = [];

	// Render imported /btw turns nicely in the TUI transcript.
	pi.registerMessageRenderer("btw-added", (message, _options, theme) => {
		const data = (message.details ?? {}) as { userText?: string; assistantText?: string };
		const lines = [
			theme.fg("accent", theme.bold("Imported from /btw")),
			"",
			`${theme.bold("User:")} ${data.userText ?? ""}`,
			"",
			`${theme.bold("Assistant:")} ${data.assistantText ?? ""}`,
		];
		return new Text(lines.join("\n"), 0, 0);
	});

	const extractText = (msg: AssistantMessage | UserMessage): string => {
		if (typeof msg.content === "string") return msg.content;
		return (msg.content as Array<{ type: string; text?: string }>)
			.filter((c): c is TextContent => c.type === "text")
			.map((c) => c.text)
			.join("\n");
	};

	pi.registerCommand("btw", {
		description:
			"Private aside to the model. Not stored in session history; prior /btw turns are carried forward.",
		handler: async (args, ctx) => {
			const trimmed = args.trim();

			if (trimmed === "--clear" || trimmed === "-c") {
				history = [];
				ctx.ui.notify("Cleared /btw memory", "info");
				return;
			}

			if (trimmed === "--history" || trimmed === "-h") {
				ctx.ui.notify(`/btw has ${history.length} prior turn(s)`, "info");
				return;
			}

			if (trimmed === "--add") {
				if (history.length === 0) {
					ctx.ui.notify("No /btw turn to add", "warning");
					return;
				}

				const last = history[history.length - 1]!;

				pi.sendMessage(
					{
						customType: "btw-added",
						display: true,
						content: [
							"The following was previously discussed in a `/btw` aside:\n",
							`**User:** ${last.userText}`,
							"",
							`**Assistant:** ${last.assistantText}`,
						].join("\n"),
						details: {
							userText: last.userText,
							assistantText: last.assistantText,
						},
					},
					{ triggerTurn: false },
				);

				ctx.ui.notify("Last /btw turn added to session", "info");
				return;
			}

			if (!trimmed) {
				ctx.ui.notify("Usage: /btw <message>  (or --clear, --history, --add)", "warning");
				return;
			}

			if (!ctx.model) {
				ctx.ui.notify("No model selected", "error");
				return;
			}

			const userMessage: UserMessage = {
				role: "user",
				content: [{ type: "text", text: trimmed }],
				timestamp: Date.now(),
			};

			const messages: Array<UserMessage | AssistantMessage> = history.flatMap((turn) => [
				turn.user,
				turn.assistant,
			]);
			messages.push(userMessage);

			try {
				const response = (await ctx.modelRegistry.complete(
					ctx.model,
					{
						systemPrompt:
							"You are a helpful coding assistant answering a private aside. Keep answers concise.",
						messages,
					},
					{ sessionId: uuidv7() },
				)) as AssistantMessage;

				if (response.stopReason === "aborted" || response.stopReason === "error") {
					ctx.ui.notify(
						`/btw failed: ${response.errorMessage || response.stopReason}`,
						"error",
					);
					return;
				}

				history.push({
					user: userMessage,
					assistant: response,
					userText: trimmed,
					assistantText: extractText(response),
				});

				const text = extractText(response);

				if (ctx.mode === "tui") {
					ctx.ui.setEditorText(text);
					ctx.ui.notify("/btw response loaded into editor", "info");
				} else if (ctx.mode === "print" || ctx.mode === "json") {
					console.log(`\n[btw]\n${text}\n`);
				} else {
					ctx.ui.notify(text.slice(0, 500), "info");
				}
			} catch (err) {
				ctx.ui.notify(
					`/btw error: ${err instanceof Error ? err.message : String(err)}`,
					"error",
				);
			}
		},
	});
}
