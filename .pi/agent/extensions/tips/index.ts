import { readFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TIP_INTERVAL_TURNS = 3;
const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
const tipsBlock = readme.match(/```pi-tips\r?\n([\s\S]*?)\r?\n```/);
if (!tipsBlock) throw new Error("Extensions README is missing its pi-tips block");
const tips = tipsBlock[1]
	.split(/\r?\n/)
	.map((tip) => tip.trim())
	.filter(Boolean);

export default function tipsExtension(pi: ExtensionAPI) {
	let tipIndex = 0;
	let turnsSinceTip = 0;

	const showTip = (ctx: { hasUI: boolean; ui: { notify: (message: string, level: "info") => void } }) => {
		if (!ctx.hasUI || tips.length === 0) return;
		ctx.ui.notify(`Tip: ${tips[tipIndex % tips.length]}`, "info");
		tipIndex++;
	};

	pi.on("session_start", (event, ctx) => {
		if (event.reason === "reload") return;
		turnsSinceTip = 0;
		showTip(ctx);
	});

	pi.on("turn_end", (_event, ctx) => {
		if (!ctx.hasUI || tips.length === 0) return;
		turnsSinceTip++;
		if (turnsSinceTip >= TIP_INTERVAL_TURNS) {
			turnsSinceTip = 0;
			showTip(ctx);
		}
	});
}
