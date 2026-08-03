import { existsSync, readFileSync } from "node:fs";
import { basename, resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	extractGithubPrNumber,
	extractGithubRepoName,
	isAllowedReviewBashCommand,
	isGithubPrNumber,
	isGithubPrUrl,
	isLikelyModifyingCommand,
	isReviewDprintCommand,
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
		description: "Run one constrained review response that updates REVIEW-{repo}-{PR NUMBER}.md from a GitHub PR URL or PR number",
		handler: async (args, ctx) => {
			const prInput = normalizePrompt(args);
			if (!prInput) {
				ctx.ui.notify(
					"Usage: /review \"https://github.com/<owner>/<repo>/pull/<number>\" or /review <pr-number>",
					"error",
				);
				return;
			}

			const inputIsUrl = isGithubPrUrl(prInput);
			const inputIsNumber = isGithubPrNumber(prInput);
			if (!inputIsUrl && !inputIsNumber) {
				ctx.ui.notify("/review supports a GitHub PR URL or numeric PR number.", "error");
				return;
			}

			const prUrl = inputIsUrl ? prInput : "";
			const prNumber = inputIsUrl ? extractGithubPrNumber(prInput) : prInput;
			const repoName = inputIsUrl ? extractGithubRepoName(prInput) : basename(process.cwd());
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

			// AIDEV-NOTE: /review allows URL or PR number input; one review-file write, one dprint pass, constrained bash.
			const reviewPrompt = [
				"Review workflow mode is active for this response.",
				"Adopt the persona of a pragmatic senior code reviewer.",
				`Review target: ${inputIsUrl ? prUrl : `PR #${prNumber} (current repo)`}`,
				`PR number: ${prNumber}`,
				"Run gh/git commands needed for this exact flow:",
				"1) If needed, check whether the PR is already checked out: gh pr view --json number,headRefName",
				"2) Get head branch and merge target from PR metadata.",
				"3) If current branch is the PR head branch, run 'git pull'. Otherwise run:",
				"   - git fetch origin <head-branch>:<head-branch>",
				"   - git checkout <head-branch>",
				"4) Generate diff with: base=$(gh pr view --json baseRefName | jq -r '.baseRefName') && git fetch origin $base:$base && git diff $base..HEAD",
				"5) Fetch PR title/body context with:",
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
				`After updating ${reviewFileName}, try running 'dprint fmt ${reviewFileName}' once via bash.`,
				"If dprint is unavailable or fails, continue without failing the review update.",
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
				content: `[REVIEW CONSTRAINED MODE]\nAllow one write/edit call to ${expectedReviewFileName || "REVIEW-{repo}-{PR NUMBER}.md"} and one optional 'dprint fmt ${expectedReviewFileName || "REVIEW-{repo}-{PR NUMBER}.md"}' bash call. For bash, also allow only constrained GitHub PR review commands for the configured PR URL/number. Block all other modifying actions.`,
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
			if (expectedReviewFileName && isReviewDprintCommand(command, expectedReviewFileName)) {
				if (reviewFormatCallsRemaining <= 0) {
					return {
						block: true,
						reason: "Blocked by /review mode: the optional review-file dprint call was already used.",
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
