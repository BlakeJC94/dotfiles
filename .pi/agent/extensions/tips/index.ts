import { readFileSync } from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const MIN_TIP_INTERVAL_TURNS = 6;
const MAX_TIP_INTERVAL_TURNS = 10;
const randomTipInterval = () =>
	Math.floor(Math.random() * (MAX_TIP_INTERVAL_TURNS - MIN_TIP_INTERVAL_TURNS + 1)) + MIN_TIP_INTERVAL_TURNS;
const SNIPPETS_REMINDER = "Snippets active: :review, :debug, :test, :explain, :plan, :verify";
const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
const tipsBlock = readme.match(/```pi-tips\r?\n([\s\S]*?)\r?\n```/);
if (!tipsBlock) throw new Error("Extensions README is missing its pi-tips block");
const tips = tipsBlock[1]
	.split(/\r?\n/)
	.map((tip) => tip.trim())
	.filter(Boolean);

export default function tipsExtension(pi: ExtensionAPI) {
	let tipIndex = 0;
	let turnsUntilTip = randomTipInterval();
	let tipDue = false;

	const showReminder = (ctx: ExtensionContext, tip?: string) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setWidget(
			"tips-snippets-reminder",
			(_tui, theme) => {
				const content = tip
					? [`Tip: ${tip}`, "", theme.fg("muted", SNIPPETS_REMINDER)]
					: [theme.fg("muted", SNIPPETS_REMINDER)];
				return new Text(content.join("\n"), 0, 0);
			},
			{ placement: "aboveEditor" },
		);
	};

	const showTip = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui" || tips.length === 0) return;
		showReminder(ctx, tips[tipIndex % tips.length]);
		tipIndex++;
	};

	pi.on("session_start", (event, ctx) => {
		turnsUntilTip = randomTipInterval();
		tipDue = false;
		if (event.reason === "reload") {
			showReminder(ctx);
			return;
		}
		showTip(ctx);
	});

	pi.on("agent_start", (_event, ctx) => {
		if (ctx.mode === "tui") ctx.ui.setWidget("tips-snippets-reminder", undefined);
	});

	pi.on("turn_end", (_event, ctx) => {
		if (ctx.mode !== "tui" || tips.length === 0) return;
		turnsUntilTip--;
		if (turnsUntilTip === 0) tipDue = true;
	});

	pi.on("agent_settled", (_event, ctx) => {
		if (tipDue) {
			tipDue = false;
			showTip(ctx);
			turnsUntilTip = randomTipInterval();
		} else {
			showReminder(ctx);
		}
	});
}
