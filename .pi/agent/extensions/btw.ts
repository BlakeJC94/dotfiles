import { uuidv7 } from "@earendil-works/pi-ai";
import { getMarkdownTheme, type ExtensionAPI, type ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import type { AssistantMessage, TextContent, UserMessage } from "@earendil-works/pi-ai";
import { Markdown, Text } from "@earendil-works/pi-tui";

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
		const data = (message.details ?? {}) as { turns?: Array<{ userText: string; assistantText: string }> };
		const turns = data.turns ?? [];
		const lines: string[] = [theme.fg("accent", theme.bold("Imported from /btw")), ""];
		for (const turn of turns) {
			lines.push(`${theme.bold("User:")} ${turn.userText}`);
			lines.push("");
			lines.push(`${theme.bold("Assistant:")} ${turn.assistantText}`);
			lines.push("");
		}
		return new Text(lines.join("\n"), 0, 0);
	});

	const extractText = (msg: AssistantMessage | UserMessage): string => {
		if (typeof msg.content === "string") return msg.content;
		return (msg.content as Array<{ type: string; text?: string }>)
			.filter((c): c is TextContent => c.type === "text")
			.map((c) => c.text)
			.join("\n");
	};

	const renderBtwWidget = (
		ctx: ExtensionCommandContext,
		currentUser?: string,
		streamingAssistant?: string,
	) => {
		if (ctx.mode !== "tui") return;

		const parts: string[] = [];
		for (const turn of history) {
			parts.push(`**User:** ${turn.userText}`);
			parts.push("");
			parts.push(`**Assistant:** ${turn.assistantText}`);
			parts.push("");
		}
		if (currentUser) {
			parts.push(`**User:** ${currentUser}`);
			parts.push("");
			parts.push(`**Assistant:** ${streamingAssistant ?? ""}▌`);
		}

		const markdown = parts.join("\n");
		ctx.ui.setWidget("btw", (_tui, _theme) => new Markdown(markdown, 0, 0, getMarkdownTheme()));
	};

	const clearBtwWidget = (ctx: ExtensionCommandContext) => {
		if (ctx.mode === "tui") {
			ctx.ui.setWidget("btw", undefined);
		}
	};

	pi.registerCommand("btw", {
		description:
			"Private aside to the model. Not stored in session history; prior /btw turns are carried forward.",
		handler: async (args, ctx) => {
			const trimmed = args.trim();

			if (trimmed === "--clear" || trimmed === "-c") {
				history = [];
				clearBtwWidget(ctx);
				ctx.ui.notify("Cleared /btw memory", "info");
				return;
			}

			if (trimmed === "--history" || trimmed === "-h") {
				ctx.ui.notify(`/btw has ${history.length} prior turn(s)`, "info");
				return;
			}

			if (trimmed === "--close") {
				clearBtwWidget(ctx);
				ctx.ui.notify("Closed /btw widget", "info");
				return;
			}

			if (trimmed === "--add") {
				if (history.length === 0) {
					ctx.ui.notify("No /btw turn to add", "warning");
					return;
				}

				const parts: string[] = [
					"The following was previously discussed in a `/btw` aside:\n",
				];
				for (const turn of history) {
					parts.push(`**User:** ${turn.userText}`);
					parts.push("");
					parts.push(`**Assistant:** ${turn.assistantText}`);
					parts.push("");
				}

				pi.sendMessage(
					{
						customType: "btw-added",
						display: true,
						content: parts.join("\n"),
						details: {
							turns: history.map((turn) => ({
								userText: turn.userText,
								assistantText: turn.assistantText,
							})),
						},
					},
					{ triggerTurn: false },
				);

				clearBtwWidget(ctx);
				history = [];
				ctx.ui.notify("Added /btw chain to session and cleared side channel", "info");
				return;
			}

			if (!trimmed) {
				ctx.ui.notify("Usage: /btw <message>  (or --clear, --history, --add, --close)", "warning");
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

			if (ctx.mode === "tui") {
				renderBtwWidget(ctx, trimmed);
			}

			try {
				const stream = ctx.modelRegistry.streamSimple(
					ctx.model,
					{
						systemPrompt:
							"You are a helpful coding assistant answering a private aside. Keep answers concise.",
						messages,
					},
					{ sessionId: uuidv7() },
				);

				let streamed = "";
				let finalResponse: AssistantMessage | undefined;

				for await (const event of stream as AsyncIterable<{
					type: string;
					delta?: string;
					message?: AssistantMessage;
					errorMessage?: string;
					reason?: string;
				}>) {
					if (event.type === "text_delta" && event.delta) {
						streamed += event.delta;
						if (ctx.mode === "tui") {
							renderBtwWidget(ctx, trimmed, streamed);
						}
					} else if (event.type === "done" && event.message) {
						finalResponse = event.message;
					} else if (event.type === "error") {
						throw new Error(event.errorMessage || "stream error");
					}
				}

				const response = finalResponse;
				if (!response) {
					ctx.ui.notify("/btw produced no response", "warning");
					return;
				}

				history.push({
					user: userMessage,
					assistant: response,
					userText: trimmed,
					assistantText: extractText(response),
				});

				if (ctx.mode === "tui") {
					renderBtwWidget(ctx);
				} else if (ctx.mode === "print" || ctx.mode === "json") {
					console.log(`\n[btw]\n${extractText(response)}\n`);
				} else {
					ctx.ui.notify(extractText(response).slice(0, 500), "info");
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
