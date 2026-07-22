import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	extractGithubPrNumber,
	extractGithubRepoName,
	isAllowedReviewBashCommand,
	isGithubPrUrl,
	isLikelyModifyingCommand,
	isReviewMdformatCommand,
	normalizePrompt,
} from "./utils.ts";

const WRITE_TOOLS = new Set(["edit", "write"]);

export default function reviewCommandExtension(pi: ExtensionAPI): void {
	let readOnlyResponsesRemaining = 0;
	let reviewWriteCallsRemaining = 0;
	let reviewFormatCallsRemaining = 0;
	let expectedPrUrl = "";
	let expectedPrNumber = "";
	let expectedReviewFileName = "";
	let expectedReviewPath = "";

	function updateStatus(ctx: ExtensionContext): void {
		if (readOnlyResponsesRemaining > 0) {
			ctx.ui.setStatus("review-command", ctx.ui.theme.fg("warning", "review:constrained + review-file write"));
			return;
		}
		ctx.ui.setStatus("review-command", undefined);
	}

	pi.registerCommand("review", {
		description: "Run one constrained review response that updates REVIEW-{repo}-{PR NUMBER}.md from a GitHub PR URL",
		handler: async (args, ctx) => {
			const prUrl = normalizePrompt(args);
			if (!prUrl) {
				ctx.ui.notify("Usage: /review \"https://github.com/<owner>/<repo>/pull/<number>\"", "error");
				return;
			}
			if (!isGithubPrUrl(prUrl)) {
				ctx.ui.notify("/review currently supports GitHub PR URLs only.", "error");
				return;
			}

			const repoName = extractGithubRepoName(prUrl);
			const prNumber = extractGithubPrNumber(prUrl);
			const reviewFileName = `REVIEW-${repoName}-${prNumber}.md`;
			const reviewPath = resolve(process.cwd(), reviewFileName);
			const reviewExists = existsSync(reviewPath);
			const existingReview = reviewExists ? readFileSync(reviewPath, "utf8") : "";

			readOnlyResponsesRemaining = 1;
			reviewWriteCallsRemaining = 1;
			reviewFormatCallsRemaining = 1;
			expectedPrUrl = prUrl;
			expectedPrNumber = prNumber;
			expectedReviewFileName = reviewFileName;
			expectedReviewPath = reviewPath;
			updateStatus(ctx);

			// AIDEV-NOTE: /review allows one REVIEW-{PR}.md write/edit, one optional mdformat pass, and constrained bash.
			const reviewPrompt = [
				"Review workflow mode is active for this response.",
				"Adopt the persona of a pragmatic senior code reviewer.",
				`Review target PR URL: ${prUrl}`,
				`PR number: ${prNumber}`,
				"Run gh/git commands needed for this exact flow:",
				"1) Get head branch and merge target from PR metadata.",
				"2) If current branch is the PR head branch, run 'git pull'. Otherwise run:",
				"   - git remote set-branches --add origin <head-branch>",
				"   - git fetch",
				"   - git checkout <head-branch>",
				"3) Generate diff with: git diff $(git merge-base <target-branch> HEAD)..HEAD",
				"4) Fetch PR title/body context with:",
				"   gh pr view --json title,body <pr-number> --jq '. as $o | [\"title\", \"body\"] | map(\"## \\(.)\\n\\n\\($o[.])\\n\") | .[]'",
				"Use the computed diff as source of truth. Use PR title/body as supporting context.",
				`Update ${reviewFileName} at project root with a first-pass review focused on glaring issues and risky changes.`,
				"Top line must be a quick PR health check: size (S/M/L/XL) and readiness (Ready/Needs Work/Blocked).",
				"Assess size using review complexity, blast radius, and risk - not raw line count only.",
				"Exclude generated files/artifacts and lockfile-only churn from size/risk scoring unless they are central.",
				"If the PR is too large or too risky for high-quality review, say so explicitly and explain why in 1-2 bullets.",
				"Summarize the change in short, clear chunks.",
				"Include actionable findings with severity and concrete file/area references from the diff.",
				`Create a reviewer checklist in ${reviewFileName} using Markdown task items (- [ ]).`,
				"Top-level checklist items must be every non-generated changed file.",
				"Under each file checklist item, add an unordered sublist of file-specific checks.",
				"Exclude generated files/artifacts from this checklist unless they need manual review.",
				"Checklist must help a human reviewer complete a full review from scratch.",
				"Add a section of thoughtful questions the developer should consider during review.",
				"Write all report points as short sentences using dot points and/or nested lists.",
				"Avoid long paragraphs.",
				"Each word must earn its place.",
				"Keep the review file short and minimize words.",
				"Add a blank line after each list item for readability.",
				`You may make exactly one modifying tool call, and it must target ${reviewFileName} via write or edit.`,
				`After updating ${reviewFileName}, try running 'mdformat ${reviewFileName}' once via bash.`,
				"If mdformat is unavailable or fails, continue without failing the review update.",
				"Do not modify any other file.",
				`After updating ${reviewFileName}, reply with a short confirmation only.`,
				"Do not repeat the full review in your response.",
				"",
				`Current ${reviewFileName} content (if present):`,
				existingReview || "<missing>",
			].join("\n");

			if (ctx.isIdle()) {
				pi.sendUserMessage(reviewPrompt);
				return;
			}

			pi.sendUserMessage(reviewPrompt, { deliverAs: "followUp" });
		},
	});

	pi.on("before_agent_start", async () => {
		if (readOnlyResponsesRemaining <= 0) return;
		return {
			message: {
				customType: "review-constrained-context",
				content: `[REVIEW CONSTRAINED MODE]\nAllow one write/edit call to ${expectedReviewFileName || "REVIEW-{repo}-{PR NUMBER}.md"} and one optional 'mdformat ${expectedReviewFileName || "REVIEW-{repo}-{PR NUMBER}.md"}' bash call. For bash, also allow only constrained GitHub PR review commands for the configured PR URL/number. Block all other modifying actions.`,
				display: false,
			},
		};
	});

	pi.on("tool_call", async (event) => {
		if (readOnlyResponsesRemaining <= 0) return;

		if (WRITE_TOOLS.has(event.toolName)) {
			const rawPath = String(event.input.path ?? "").replace(/^@/, "");
			const targetPath = resolve(process.cwd(), rawPath);
			if (!expectedReviewPath || targetPath !== expectedReviewPath) {
				return {
					block: true,
					reason: `Blocked by /review mode: only ${expectedReviewFileName || "REVIEW-{repo}-{PR NUMBER}.md"} may be modified.`,
				};
			}
			if (reviewWriteCallsRemaining <= 0) {
				return {
					block: true,
					reason: "Blocked by /review mode: the single allowed review-file modification was already used.",
				};
			}
			reviewWriteCallsRemaining -= 1;
			return;
		}

		if (event.toolName === "bash") {
			const command = String(event.input.command ?? "");
			if (expectedReviewFileName && isReviewMdformatCommand(command, expectedReviewFileName)) {
				if (reviewFormatCallsRemaining <= 0) {
					return {
						block: true,
						reason: "Blocked by /review mode: the optional review-file mdformat call was already used.",
					};
				}
				reviewFormatCallsRemaining -= 1;
				return;
			}
			if (isAllowedReviewBashCommand(command, expectedPrUrl, expectedPrNumber)) {
				return;
			}
			if (isLikelyModifyingCommand(command)) {
				return {
					block: true,
					reason: `Blocked modifying bash command in /review mode: ${command}`,
				};
			}
		}
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (readOnlyResponsesRemaining > 0) {
			readOnlyResponsesRemaining -= 1;
			reviewWriteCallsRemaining = 0;
			reviewFormatCallsRemaining = 0;
			expectedPrUrl = "";
			expectedPrNumber = "";
			expectedReviewFileName = "";
			expectedReviewPath = "";
			updateStatus(ctx);
		}
	});

	pi.on("session_start", async (_event, ctx) => {
		readOnlyResponsesRemaining = 0;
		reviewWriteCallsRemaining = 0;
		reviewFormatCallsRemaining = 0;
		expectedPrUrl = "";
		expectedPrNumber = "";
		expectedReviewFileName = "";
		expectedReviewPath = "";
		updateStatus(ctx);
	});
}
