const MODIFYING_PATTERNS = [
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bchgrp\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/\bdd\b/i,
	/\bshred\b/i,
	/(^|[^<])>(?!>)/,
	/>>/,
	/\bnpm\s+(install|uninstall|update|ci|link|publish)\b/i,
	/\byarn\s+(add|remove|install|publish)\b/i,
	/\bpnpm\s+(add|remove|install|publish)\b/i,
	/\bpip\s+(install|uninstall)\b/i,
	/\bapt(-get)?\s+(install|remove|purge|update|upgrade)\b/i,
	/\bbrew\s+(install|uninstall|upgrade)\b/i,
	/\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert|tag|init|clone)\b/i,
];

const GITHUB_PR_URL_RE =
	/^https:\/\/github\.com\/([^\s/]+)\/([^\s/]+)\/pull\/(\d+)(?:[/?#][^\s]*)?$/i;

export function isLikelyModifyingCommand(command: string): boolean {
	return MODIFYING_PATTERNS.some((pattern) => pattern.test(command));
}

export function normalizePrompt(input: string): string {
	const trimmed = input.trim();
	if (
		(trimmed.startsWith('"') && trimmed.endsWith('"')) ||
		(trimmed.startsWith("'") && trimmed.endsWith("'"))
	) {
		return trimmed.slice(1, -1).trim();
	}
	return trimmed;
}

export function normalizeCommand(input: string): string {
	return input.trim().replace(/\s+/g, " ");
}

export function isGithubPrUrl(input: string): boolean {
	return GITHUB_PR_URL_RE.test(input.trim());
}

export function extractGithubRepoName(input: string): string {
	const match = input.trim().match(GITHUB_PR_URL_RE);
	return match?.[2] ?? "";
}

export function extractGithubPrNumber(input: string): string {
	const match = input.trim().match(GITHUB_PR_URL_RE);
	return match?.[3] ?? "";
}

function hasUnsafeShellOperators(command: string): boolean {
	return /[;&|`<>\n\r]/.test(command);
}

function isAllowedGhPrView(command: string, prUrl: string, prNumber: string): boolean {
	if (!/^(gh|git hub) pr view(\s|$)/i.test(command)) {
		return false;
	}
	if (!/\s--json\s/i.test(command)) {
		return false;
	}
	if (command.includes(prUrl)) {
		return true;
	}
	if (prNumber && new RegExp(`(^|\\s)${prNumber}(\\s|$)`).test(command)) {
		return true;
	}
	return false;
}

export function isReviewMdformatCommand(command: string, reviewFileName: string): boolean {
	const normalized = normalizeCommand(command);
	const escapedName = reviewFileName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
	return new RegExp(`^(mdformat|python -m mdformat) (\\./)?${escapedName}$`, "i").test(normalized);
}

export function isAllowedReviewBashCommand(command: string, prUrl: string, prNumber: string): boolean {
	const normalized = normalizeCommand(command);
	if (!normalized) return false;
	if (hasUnsafeShellOperators(normalized)) return false;

	if (isAllowedGhPrView(normalized, prUrl, prNumber)) return true;
	if (/^git branch --show-current$/i.test(normalized)) return true;
	if (/^git pull$/i.test(normalized)) return true;
	if (/^git remote set-branches --add origin [A-Za-z0-9._/-]+$/i.test(normalized)) return true;
	if (/^git fetch$/i.test(normalized)) return true;
	if (/^git checkout [A-Za-z0-9._/-]+$/i.test(normalized)) return true;
	if (/^git merge-base [A-Za-z0-9._/-]+ HEAD$/i.test(normalized)) return true;
	if (/^git diff \$\(git merge-base [A-Za-z0-9._/-]+ HEAD\)\.\.HEAD$/i.test(normalized)) return true;
	if (/^git diff [0-9a-f]{7,40}\.\.HEAD$/i.test(normalized)) return true;

	return false;
}
